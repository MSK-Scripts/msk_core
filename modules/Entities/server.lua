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

-- On the server `isPlayerEntity` is either false (vehicles) or the server id of
-- the player to search around (MSK.GetClosestPlayer passes it that way). That
-- player is the origin when no coords are given and is never returned himself.
--
-- The old version called GetPlayerPed(isPlayerEntity) with true or false when
-- coords were missing, and `a or b and c` accepted the first entity without the
-- self check, so the calling player could come back as his own closest player.
local function resolveOrigin(isPlayerEntity, coords)
    local sourceId = tonumber(isPlayerEntity)
    local sourcePed = sourceId and GetPlayerPed(sourceId) or 0

    if coords then
        return vector3(coords.x, coords.y, coords.z), sourcePed
    end

    if sourcePed ~= 0 then
        return GetEntityCoords(sourcePed), sourcePed
    end

    error('coords are required on the server unless a player id is given', 3)
end

---The closest player or vehicle. With `maxDistance` only entities within that
---range count. Nothing found returns -1, -1.
function MSK.GetClosestEntity(isPlayerEntity, coords, entities, maxDistance)
    local origin, sourcePed = resolveOrigin(isPlayerEntity, coords)
    local closestEntity, closestDistance = -1, -1

    maxDistance = tonumber(maxDistance)

    for k, entity in pairs(entities or getEntities(isPlayerEntity)) do
        if not (isPlayerEntity and sourcePed ~= 0 and entity == sourcePed) then
            local distance = #(origin - GetEntityCoords(entity))

            if (not maxDistance or distance <= maxDistance) and (closestDistance == -1 or distance < closestDistance) then
                closestEntity, closestDistance = isPlayerEntity and k or entity, distance
            end
        end
    end

    return closestEntity, closestDistance
end

function MSK.GetClosestEntities(isPlayerEntity, coords, distance, entities)
    local origin, sourcePed = resolveOrigin(isPlayerEntity, coords)
    local closestEntities = {}

    -- Without a distance every entity counts. It used to compare against nil.
    distance = tonumber(distance) or math.huge

    for k, entity in pairs(entities or getEntities(isPlayerEntity)) do
        if not (isPlayerEntity and sourcePed ~= 0 and entity == sourcePed) then
            if #(origin - GetEntityCoords(entity)) <= distance then
                closestEntities[#closestEntities + 1] = isPlayerEntity and k or entity
            end
        end
    end

    return closestEntities
end

return true
