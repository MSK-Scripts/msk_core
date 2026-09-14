--------------------------------------------------------------------------------
-- MSK.VehicleProperties (server)
--
-- The server cannot apply vehicle properties itself, only the client that owns
-- the entity can. Set writes them into a state bag of the vehicle; the owning
-- client applies them and the server clears the bag again.
--
--   local vehicle = CreateVehicleServerSetter(model, 'automobile', x, y, z, heading)
--   MSK.VehicleProperties.Set(vehicle, props)
--
-- When nobody owns the vehicle yet (no player in range), the properties are
-- applied as soon as a client picks it up and the state reaches it.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Props = {}

local STATE_KEY = 'msk_core:vehicleProperties'

---@param vehicle number server entity handle
---@param props table
---@param fixVehicle? boolean
---@return boolean queued
function Props.Set(vehicle, props, fixVehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    assert(type(props) == 'table', 'Parameter "props" has to be a table on function MSK.VehicleProperties.Set')

    Entity(vehicle).state:set(STATE_KEY, { props = props, fix = fixVehicle == true }, true)
    return true
end

if IS_CORE then
    -- The owning client reports that it applied the properties. Only the owner
    -- of that vehicle may clear its bag, anyone else could wipe properties that
    -- were never applied.
    RegisterNetEvent('msk_core:vehiclePropertiesApplied', function(netId)
        local playerId = source
        local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)

        if vehicle == 0 or not DoesEntityExist(vehicle) then return end
        if NetworkGetEntityOwner(vehicle) ~= playerId then return end
        if Entity(vehicle).state[STATE_KEY] == nil then return end

        Entity(vehicle).state:set(STATE_KEY, nil, true)
    end)
end

return Props
