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
