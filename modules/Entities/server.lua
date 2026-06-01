local function getEntities(isPlayerEntity)
    local entities = {}

    if isPlayerEntity then
        for _, playerId in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(playerId)
            if DoesEntityExist(ped) then
                entities[playerId] = ped
            end
        end
    else
        entities = GetAllVehicles()
    end

    return entities
end

function MSK.GetClosestEntity(isPlayerEntity, coords, entities)
    local closestEntity, closestDistance = -1, -1
    local entites = entities or getEntities(isPlayerEntity)

    coords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(GetPlayerPed(isPlayerEntity))

    for k, entity in pairs(entites) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestDistance == -1 or distance <= closestDistance and (not isPlayerEntity or isPlayerEntity and entity ~= GetPlayerPed(isPlayerEntity)) then
            closestEntity, closestDistance = isPlayerEntity and k or entity, distance
        end
    end

    return closestEntity, closestDistance
end

function MSK.GetClosestEntities(isPlayerEntity, coords, distance, entities)
    local entites = entities or getEntities(isPlayerEntity)
    local closestEntities = {}

    coords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(GetPlayerPed(isPlayerEntity))

    for k, entity in pairs(entites) do
        local dist = #(coords - GetEntityCoords(entity))

        if dist <= distance and (not isPlayerEntity or isPlayerEntity and entity ~= GetPlayerPed(isPlayerEntity)) then
            closestEntities[#closestEntities + 1] = isPlayerEntity and k or entity
        end
    end

    return closestEntities
end

return true
