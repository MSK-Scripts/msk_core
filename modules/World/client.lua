function MSK.IsSpawnPointClear(coords, maxDistance)
    local nearbyVehicles = {}

    -- Same default as the server side. Without it the comparison below hit nil.
    maxDistance = tonumber(maxDistance) or 5.0

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        coords = MSK.Player.coords
    end

    for _, vehicle in pairs(GetGamePool('CVehicle')) do
        local distance = #(coords - GetEntityCoords(vehicle))

        if distance <= maxDistance then
            nearbyVehicles[#nearbyVehicles + 1] = vehicle
        end
    end

    return #nearbyVehicles == 0
end
exports('IsSpawnPointClear', MSK.IsSpawnPointClear)

---@param ped number
---@param transparent? boolean
---@param timeout? number milliseconds, default 5000
---@return number|nil mugshot, string|nil txd nil when the headshot did not get ready
function MSK.GetPedMugshot(ped, transparent, timeout)
    assert(ped and DoesEntityExist(ped), 'Parameter "ped" is nil or the PlayerPed does not exist')
    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)
    local deadline = GetGameTimer() + (tonumber(timeout) or 5000)

    -- Limited: a headshot that never gets ready (too many registered, ped gone)
    -- used to keep the calling thread waiting forever.
    while not IsPedheadshotReady(mugshot) do
        if GetGameTimer() > deadline or not DoesEntityExist(ped) then
            UnregisterPedheadshot(mugshot)
            MSK.Logging('error', 'MSK.GetPedMugshot: the headshot did not get ready in time.')
            return nil
        end

        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end
exports('GetPedMugshot', MSK.GetPedMugshot)

---@param coords? vector3 default the player's position
---@param maxDistance? number only players within this range count
---@return number player, number distance -1, -1 when none was found
function MSK.GetClosestPlayer(coords, maxDistance)
    return MSK.GetClosestEntity(true, coords, maxDistance)
end
exports('GetClosestPlayer', MSK.GetClosestPlayer)

function MSK.GetClosestPlayers(coords, distance)
    return MSK.GetClosestEntities(true, coords, distance)
end
exports('GetClosestPlayers', MSK.GetClosestPlayers)

return true
