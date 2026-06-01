function MSK.IsSpawnPointClear(coords, maxDistance)
    local nearbyVehicles = {}

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

function MSK.GetPedMugshot(ped, transparent)
    assert(ped and DoesEntityExist(ped), 'Parameter "ped" is nil or the PlayerPed does not exist')
    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end
exports('GetPedMugshot', MSK.GetPedMugshot)

function MSK.GetClosestPlayer(coords)
    return MSK.GetClosestEntity(true, coords)
end
exports('GetClosestPlayer', MSK.GetClosestPlayer)

function MSK.GetClosestPlayers(coords, distance)
    return MSK.GetClosestEntities(true, coords, distance)
end
exports('GetClosestPlayers', MSK.GetClosestPlayers)

return true
