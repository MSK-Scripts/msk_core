local IS_CORE = GetCurrentResourceName() == 'msk_core'

function MSK.GetClosestVehicle(coords, vehicles)
    return MSK.GetClosestEntity(false, coords, vehicles)
end
exports('GetClosestVehicle', MSK.GetClosestVehicle)

function MSK.GetClosestVehicles(coords, distance, vehicles)
    return MSK.GetClosestEntities(false, coords, distance, vehicles)
end
exports('GetClosestVehicles', MSK.GetClosestVehicles)

function MSK.GetClosestVehicleWithPlate(plate, coords, distance, vehicles)
    vehicles = MSK.GetClosestEntities(false, coords, distance, vehicles)
    plate = MSK.String.Trim(plate)

    for i = 1, #vehicles do
        if DoesEntityExist(vehicles[i]) then
            if MSK.String.Trim(GetVehicleNumberPlateText(vehicles[i])) == plate and #(coords - GetEntityCoords(vehicles[i])) <= distance then
                return vehicles[i]
            end
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
    -- Frameworks that are not listed here (ox_core, STANDALONE) return nil,
    -- same stance as the Offline module.
    local vehicleTables = {
        ESX    = { tbl = 'owned_vehicles',  cols = '`vehicle`'          },
        QBCore = { tbl = 'player_vehicles', cols = '`vehicle`, `hash`'  },
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

        if MSK.Bridge.Framework.Type == 'QBCore' then
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
    if not ped then return end
    if not vehicle then vehicle = GetVehiclePedIsIn(ped, false) end

    for i = -1, 16 do
        if GetPedInVehicleSeat(vehicle, i) == ped then return i end
    end

    return -1
end
exports('GetPedVehicleSeat', MSK.GetPedVehicleSeat)

return true
