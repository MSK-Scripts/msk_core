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

function MSK.GetClosestEntity(isPlayerEntity, coords)
    local closestEntity, closestDistance = -1, -1
    local entites = getEntities(isPlayerEntity)

    coords = coords and vector3(coords.x, coords.y, coords.z) or MSK.Player.coords

    for k, entity in pairs(entites) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestDistance == -1 or distance <= closestDistance then
            closestEntity, closestDistance = isPlayerEntity and k or entity, distance
        end
    end

    return closestEntity, closestDistance
end

function MSK.GetClosestEntities(isPlayerEntity, coords, distance)
    local entites = getEntities(isPlayerEntity)
    local closestEntities = {}

    coords = coords and vector3(coords.x, coords.y, coords.z) or MSK.Player.coords

    for k, entity in pairs(entites) do
        local dist = #(coords - GetEntityCoords(entity))

        if dist <= distance then
            closestEntities[#closestEntities + 1] = isPlayerEntity and k or entity
        end
    end

    return closestEntities
end

-- Death detection (singleton in the core)
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

return true
