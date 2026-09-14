local IS_CORE = GetCurrentResourceName() == 'msk_core'

local function getEntities(isPlayerEntity)
    local entities = {}

    if isPlayerEntity then
        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) and ped ~= MSK.Player.ped then
                entities[player] = ped
            end
        end
    else
        entities = GetGamePool('CVehicle')
    end

    return entities
end

---The closest player or vehicle. With `maxDistance` only entities within that
---range count. Nothing found returns -1, -1.
function MSK.GetClosestEntity(isPlayerEntity, coords, maxDistance)
    local closestEntity, closestDistance = -1, -1
    local entites = getEntities(isPlayerEntity)

    coords = coords and vector3(coords.x, coords.y, coords.z) or MSK.Player.coords
    maxDistance = tonumber(maxDistance)

    for k, entity in pairs(entites) do
        local distance = #(coords - GetEntityCoords(entity))

        if (not maxDistance or distance <= maxDistance) and (closestDistance == -1 or distance <= closestDistance) then
            closestEntity, closestDistance = isPlayerEntity and k or entity, distance
        end
    end

    return closestEntity, closestDistance
end

function MSK.GetClosestEntities(isPlayerEntity, coords, distance)
    local entites = getEntities(isPlayerEntity)
    local closestEntities = {}

    coords = coords and vector3(coords.x, coords.y, coords.z) or MSK.Player.coords

    -- Without a distance every entity counts. It used to compare against nil.
    distance = tonumber(distance) or math.huge

    for k, entity in pairs(entites) do
        local dist = #(coords - GetEntityCoords(entity))

        if dist <= distance then
            closestEntities[#closestEntities + 1] = isPlayerEntity and k or entity
        end
    end

    return closestEntities
end

local function toVector3(coords)
    return coords and vector3(coords.x, coords.y, coords.z) or MSK.Player.coords
end

-- Walks one of the game pools and collects everything within maxDistance,
-- sorted from near to far. `skip` filters entities out before measuring.
local function nearbyFromPool(poolName, coords, maxDistance, skip)
    local pool = GetGamePool(poolName)
    local result, n = {}, 0

    for i = 1, #pool do
        local entity = pool[i]

        if not skip or not skip(entity) then
            local entityCoords = GetEntityCoords(entity)
            local distance = #(coords - entityCoords)

            if distance <= maxDistance then
                n = n + 1
                result[n] = { entity = entity, coords = entityCoords, distance = distance }
            end
        end
    end

    table.sort(result, function(a, b) return a.distance < b.distance end)
    return result
end

---Peds within `maxDistance` (default 2.0), nearest first. Player peds are left
---out unless `includePlayers` is true; your own ped is always left out.
---@param coords? vector3
---@param maxDistance? number
---@param includePlayers? boolean
---@return { entity: number, coords: vector3, distance: number }[]
function MSK.GetNearbyPeds(coords, maxDistance, includePlayers)
    local ownPed = MSK.Player.ped

    return nearbyFromPool('CPed', toVector3(coords), maxDistance or 2.0, function(ped)
        return ped == ownPed or (not includePlayers and IsPedAPlayer(ped))
    end)
end

---Objects within `maxDistance` (default 2.0), nearest first.
---@param coords? vector3
---@param maxDistance? number
---@return { entity: number, coords: vector3, distance: number }[]
function MSK.GetNearbyObjects(coords, maxDistance)
    return nearbyFromPool('CObject', toVector3(coords), maxDistance or 2.0)
end

---Vehicles within `maxDistance` (default 2.0), nearest first. The vehicle you
---sit in is left out unless `includeOwn` is true.
---@param coords? vector3
---@param maxDistance? number
---@param includeOwn? boolean
---@return { entity: number, coords: vector3, distance: number }[]
function MSK.GetNearbyVehicles(coords, maxDistance, includeOwn)
    local ownVehicle = GetVehiclePedIsIn(MSK.Player.ped, false)

    return nearbyFromPool('CVehicle', toVector3(coords), maxDistance or 2.0, function(vehicle)
        return not includeOwn and vehicle == ownVehicle
    end)
end

---Other players within `maxDistance` (default 2.0), nearest first. Your own
---player is left out unless `includeSelf` is true.
---@param coords? vector3
---@param maxDistance? number
---@param includeSelf? boolean
---@return { playerId: number, serverId: number, ped: number, coords: vector3, distance: number }[]
function MSK.GetNearbyPlayers(coords, maxDistance, includeSelf)
    coords = toVector3(coords)
    maxDistance = maxDistance or 2.0

    local ownPlayer = PlayerId()
    local result, n = {}, 0

    for _, player in ipairs(GetActivePlayers()) do
        if includeSelf or player ~= ownPlayer then
            local ped = GetPlayerPed(player)
            local pedCoords = GetEntityCoords(ped)
            local distance = #(coords - pedCoords)

            if distance <= maxDistance then
                n = n + 1
                result[n] = {
                    playerId = player,
                    serverId = GetPlayerServerId(player),
                    ped = ped,
                    coords = pedCoords,
                    distance = distance,
                }
            end
        end
    end

    table.sort(result, function(a, b) return a.distance < b.distance end)
    return result
end

---The nearest ped within `maxDistance` (default 2.0), plus its coords.
---@param coords? vector3
---@param maxDistance? number
---@param includePlayers? boolean
---@return number? ped, vector3? coords
function MSK.GetClosestPed(coords, maxDistance, includePlayers)
    local nearest = MSK.GetNearbyPeds(coords, maxDistance, includePlayers)[1]
    if nearest then return nearest.entity, nearest.coords end
end

---The nearest object within `maxDistance` (default 2.0), plus its coords.
---@param coords? vector3
---@param maxDistance? number
---@return number? object, vector3? coords
function MSK.GetClosestObject(coords, maxDistance)
    local nearest = MSK.GetNearbyObjects(coords, maxDistance)[1]
    if nearest then return nearest.entity, nearest.coords end
end

-- Death detection: a singleton that must live ONLY in msk_core. The
-- gameEventTriggered handler fires msk_core:onPlayerDeath (local + to the server)
-- on death. A consumer that eager-loads this module would otherwise add a second
-- handler and every death would be reported twice. The helper functions above
-- (GetClosestEntity/Entities) stay available to consumers on eager-load.
if IS_CORE then
exports('GetNearbyPeds', MSK.GetNearbyPeds)
exports('GetNearbyObjects', MSK.GetNearbyObjects)
exports('GetNearbyVehicles', MSK.GetNearbyVehicles)
exports('GetNearbyPlayers', MSK.GetNearbyPlayers)
exports('GetClosestPed', MSK.GetClosestPed)
exports('GetClosestObject', MSK.GetClosestObject)

local function playerDied(deathCause, killer, killerServerId)
    local playerPed = MSK.Player.ped
    local playerCoords = MSK.Player.coords

    local data = {
        killedByPlayer = false,
        victim = playerPed,
        victimCoords = playerCoords,
        victimServerId = MSK.Player.serverId
    }

    if killer and killerServerId then
        local killerPed = GetPlayerPed(killer)
        local killerCoords = GetEntityCoords(killerPed)

        data.killedByPlayer = true
        data.killer = killerPed
        data.killerCoords = killerCoords
        data.killerServerId = killerServerId
        data.distance = MSK.Math.Round(#(playerCoords - killerCoords), 2)
    end

    TriggerEvent('msk_core:onPlayerDeath', data)
    TriggerServerEvent('msk_core:onPlayerDeath', data)
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local entity = data[1]

        if IsEntityAPed(entity) and IsPedAPlayer(entity) then
            local playerPed = entity
            local died = data[4]

            if died and NetworkGetPlayerIndexFromPed(playerPed) == MSK.Player.clientId and (IsPedDeadOrDying(playerPed, true) or IsPedFatallyInjured(playerPed)) then
                local deathCause, killerEntity = GetPedCauseOfDeath(playerPed), GetPedSourceOfDeath(playerPed)
                local killer = NetworkGetPlayerIndexFromPed(killerEntity)

                if killerEntity ~= playerPed and killer and NetworkIsPlayerActive(killer) then
                    playerDied(deathCause, killer, GetPlayerServerId(killer))
                else
                    playerDied(deathCause)
                end
            end
        end
    end
end)
end

return true
