local IS_CORE = GetCurrentResourceName() == 'msk_core'

---@param coords vector3
---@param vehicles? number[] default every vehicle on the server
---@param maxDistance? number only vehicles within this range count
---@return number vehicle, number distance -1, -1 when none was found
function MSK.GetClosestVehicle(coords, vehicles, maxDistance)
    return MSK.GetClosestEntity(false, coords, vehicles, maxDistance)
end
exports('GetClosestVehicle', MSK.GetClosestVehicle)

function MSK.GetClosestVehicles(coords, distance, vehicles)
    return MSK.GetClosestEntities(false, coords, distance, vehicles)
end
exports('GetClosestVehicles', MSK.GetClosestVehicles)

function MSK.GetClosestVehicleWithPlate(plate, coords, distance, vehicles)
    plate = normalizePlate(plate)
    if not plate then return false end

    -- Without coords the server has no origin to measure from, so every
    -- vehicle is searched. It used to subtract from nil.
    if not coords then
        local vehicle = MSK.GetVehicleFromPlate(plate)
        return vehicle
    end

    vehicles = MSK.GetClosestEntities(false, coords, distance, vehicles)

    for i = 1, #vehicles do
        -- Normalised on both sides, the plain Trim compared "abc 123" and
        -- "ABC 123" as different plates.
        if DoesEntityExist(vehicles[i]) and normalizePlate(GetVehicleNumberPlateText(vehicles[i])) == plate then
            return vehicles[i]
        end
    end

    return false
end
exports('GetClosestVehicleWithPlate', MSK.GetClosestVehicleWithPlate)

---Searches EVERY vehicle on the server for this plate, without needing
---coordinates or a radius. Use MSK.GetClosestVehicleWithPlate when the hit has
---to be within a certain distance of a point.
---
---Unlike the client side this answer is complete: the server sees every
---networked vehicle, not just the ones streamed in somewhere. Vehicles whose
---sync tree has not been populated yet report an empty plate and are skipped,
---so a vehicle can be missed in the same tick it was created.
---@param plate string
---@return number|false vehicle entity handle, false when nothing matched
---@return number|nil netId network id of the vehicle
function MSK.GetVehicleFromPlate(plate)
    plate = normalizePlate(plate)
    if not plate then return false end

    local vehicles = GetAllVehicles()

    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if DoesEntityExist(vehicle) and normalizePlate(GetVehicleNumberPlateText(vehicle)) == plate then
            return vehicle, NetworkGetNetworkIdFromEntity(vehicle)
        end
    end

    return false
end
exports('GetVehicleFromPlate', MSK.GetVehicleFromPlate)

-- Serves the client side variant. The client only gets the netId: a server
-- entity handle is meaningless over there. Registered inside the core only,
-- otherwise an eager loading consumer would register a second responder whose
-- closure points back into that consumer (the v3.0.1 class of bug).
if IS_CORE then
    MSK.Register('msk_core:getVehicleFromPlate', function(playerId, plate)
        local _, netId = MSK.GetVehicleFromPlate(plate)
        return netId
    end)
end

--------------------------------------------------------------------------------
-- Model from the database
-- Unlike everything else in this module this does NOT look at spawned vehicles.
-- It answers "which model belongs to this plate according to the framework's
-- vehicle table", which also works while the vehicle is parked in a garage and
-- does not exist in the world at all.
-- Lives inside the IS_CORE guard because it needs oxmysql, which a consumer
-- resource does not necessarily have. Consumers get the export wrapper below.
--------------------------------------------------------------------------------
if IS_CORE then
    -- Table and columns per framework.
    --   ESX keeps the model INSIDE the `vehicle` JSON blob, normally as a hash.
    --   QBCore has the spawn name in `vehicle` and the hash in `hash`.
    --   Qbox uses the same player_vehicles layout as QBCore, verified against
    --   qbx_vehicles/vehicles.sql.
    -- Frameworks that are not listed here (STANDALONE) return nil, same stance
    -- as the Offline module.
    local vehicleTables = {
        ESX    = { tbl = 'owned_vehicles',  cols = '`vehicle`'          },
        QBCore = { tbl = 'player_vehicles', cols = '`vehicle`, `hash`'  },
        Qbox   = { tbl = 'player_vehicles', cols = '`vehicle`, `hash`'  },
    }

    ---Reads the model for a plate out of the framework's vehicle table.
    ---
    ---BLOCKING: runs a database query with `.await`, so it has to be called
    ---from inside a thread (CreateThread, an event handler, a callback).
    ---@param plate string
    ---@return number|nil model model hash as stored, nil when nothing was found
    ---@return string|nil name spawn name, only when the framework stores one (QBCore)
    function MSK.GetModelFromPlate(plate)
        local map = vehicleTables[MSK.Bridge.Framework.Type]
        plate = normalizePlate(plate)
        if not map or not plate then return nil end

        local row = MySQL.single.await(
            ('SELECT %s FROM `%s` WHERE `plate` = ? LIMIT 1'):format(map.cols, map.tbl), { plate }
        )

        if not row then
            -- Fallback: some scripts store the plate space padded ("ABC123  ").
            -- TRIM() cannot use the index, so this only runs when the fast,
            -- indexed lookup found nothing.
            row = MySQL.single.await(
                ('SELECT %s FROM `%s` WHERE TRIM(`plate`) = ? LIMIT 1'):format(map.cols, map.tbl), { plate }
            )
        end

        if not row then return nil end

        if MSK.Bridge.Framework.Type == 'QBCore' or MSK.Bridge.Framework.Type == 'Qbox' then
            local name = row.vehicle
            return tonumber(row.hash) or (name and GetHashKey(name)) or nil, name
        end

        -- ESX
        local ok, props = pcall(json.decode, row.vehicle)
        if not ok or type(props) ~= 'table' or props.model == nil then return nil end

        -- Usually a hash. Some setups store the spawn name instead, then the
        -- hash is derived and the name handed back as well.
        if type(props.model) == 'string' then
            return GetHashKey(props.model), props.model
        end

        return tonumber(props.model)
    end
    exports('GetModelFromPlate', MSK.GetModelFromPlate)

    -- Serves the client side variant of this function.
    MSK.Register('msk_core:getModelFromPlate', function(playerId, plate)
        return MSK.GetModelFromPlate(plate)
    end)
else
    function MSK.GetModelFromPlate(...) return exports.msk_core:GetModelFromPlate(...) end
end

function MSK.GetPedVehicleSeat(ped, vehicle)
    if not ped then return false end
    if not vehicle then vehicle = GetVehiclePedIsIn(ped, false) end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    for i = -1, 16 do
        if GetPedInVehicleSeat(vehicle, i) == ped then return i end
    end

    -- false like on the client. -1 is the driver seat, so every miss looked
    -- like the ped was driving.
    return false
end
exports('GetPedVehicleSeat', MSK.GetPedVehicleSeat)

--------------------------------------------------------------------------------
-- Spawning on the server
--
--   local vehicle, netId = MSK.SpawnVehicle('sultan', vector4(x, y, z, heading), {
--       plate = 'MSK 123',
--       props = savedProps,
--       warp = source,
--   })
--
-- Options (all optional):
--   heading    when coords carry none
--   type       'automobile', 'bike', 'boat', 'heli', 'plane', 'submarine',
--              'trailer' or 'train'
--   plate      plate text
--   props      vehicle properties, applied by the owning client
--   bucket     routing bucket
--   warp       server id of a player to put into the driver seat
--   playerId   player asked for the vehicle type
--
-- CreateVehicleServerSetter needs the vehicle type, and the server cannot read
-- it from a model. Without `type` a client is asked once per model (playerId,
-- or any connected player) and the answer is kept. A trailer cannot be told
-- apart from other vehicles by its model, pass type = 'trailer' for those.
--------------------------------------------------------------------------------
local VEHICLE_TYPES = {
    automobile = true, bike = true, boat = true, heli = true,
    plane = true, submarine = true, trailer = true, train = true,
}

local knownVehicleTypes = {}

local function resolveVehicleType(model, options)
    if options.type ~= nil then
        if not VEHICLE_TYPES[options.type] then
            return nil, ('unknown vehicle type "%s"'):format(tostring(options.type))
        end
        return options.type
    end

    if knownVehicleTypes[model] then
        return knownVehicleTypes[model]
    end

    local asker = tonumber(options.playerId)

    if not asker or not DoesPlayerExist(asker) then
        asker = tonumber(GetPlayers()[1])
    end

    if not asker then
        return nil, 'no player online to look up the vehicle type, pass options.type'
    end

    local vehicleType = MSK.Trigger('msk_core:getVehicleType', asker, model)

    if not VEHICLE_TYPES[vehicleType] then
        return nil, ('model %s is not a known vehicle'):format(model)
    end

    knownVehicleTypes[model] = vehicleType
    return vehicleType
end

---Creates a networked vehicle on the server. Blocking: it may ask a client for
---the vehicle type and waits until the entity exists.
---@param model string|number
---@param coords vector3|vector4|table
---@param options? { heading?: number, type?: string, plate?: string, props?: table, bucket?: number, warp?: number, playerId?: number }
---@return number|nil vehicle, number|nil netId nil when the vehicle could not be created
function MSK.SpawnVehicle(model, coords, options)
    options = options or {}

    if type(model) == 'string' then model = joaat(model) end
    assert(math.type(model) == 'integer', 'Parameter "model" has to be a model name or hash on function MSK.SpawnVehicle')
    assert(coords and coords.x and coords.y and coords.z, 'Parameter "coords" has to be a vector3 or vector4 on function MSK.SpawnVehicle')

    local heading = tonumber(options.heading) or tonumber(coords.w) or tonumber(coords.heading) or 0.0

    local vehicleType, err = resolveVehicleType(model, options)
    if not vehicleType then
        MSK.Logging('error', ('MSK.SpawnVehicle: %s'):format(err))
        return nil
    end

    local vehicle = CreateVehicleServerSetter(model, vehicleType, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, heading + 0.0)
    local deadline = GetGameTimer() + 5000

    while not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) do
        if GetGameTimer() > deadline then
            MSK.Logging('error', ('MSK.SpawnVehicle: vehicle %s was not created in time.'):format(model))
            return nil
        end

        Wait(0)
    end

    if options.bucket then
        SetEntityRoutingBucket(vehicle, math.floor(tonumber(options.bucket) or 0))
    end

    if options.plate then
        SetVehicleNumberPlateText(vehicle, tostring(options.plate))
    end

    if type(options.props) == 'table' then
        MSK.VehicleProperties.Set(vehicle, options.props)
    end

    local warp = tonumber(options.warp)

    if warp then
        local ped = GetPlayerPed(warp)

        if ped ~= 0 then
            -- The ped can only be put in once the vehicle reached that client,
            -- so the warp is repeated for a moment.
            local warpDeadline = GetGameTimer() + 5000

            while GetVehiclePedIsIn(ped, false) ~= vehicle and GetGameTimer() < warpDeadline do
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
                Wait(100)
            end
        end
    end

    return vehicle, NetworkGetNetworkIdFromEntity(vehicle)
end
exports('SpawnVehicle', MSK.SpawnVehicle)

return true
