MSK.GetClosestVehicle = function(coords, vehicles)
    return GetClosestEntity(false, coords, vehicles)
end
exports('GetClosestVehicle', MSK.GetClosestVehicle)

MSK.GetClosestVehicles = function(coords, distance, vehicles)
    return GetClosestEntities(false, coords, distance, vehicles)
end
exports('GetClosestVehicles', MSK.GetClosestVehicles)

MSK.GetVehicleWithPlate = function(plate, coords, distance)
    local vehicles = GetClosestEntities(false, coords, distance)
    plate = MSK.String.Trim(plate)

    for i=1, #vehicles do
        if DoesEntityExist(vehicles[i]) then
            if MSK.String.Trim(GetVehicleNumberPlateText(vehicles[i])) == plate and #(coords - GetEntityCoords(vehicles[i])) <= distance then
                return vehicles[i]
            end
        end
    end
    return false
end
exports('GetVehicleWithPlate', MSK.GetVehicleWithPlate)

MSK.GetPedVehicleSeat = function(ped, vehicle)
    if not ped then return end
    if not vehicle then GetVehiclePedIsIn(ped, false) end
    
    for i = -1, 16 do
        if (GetPedInVehicleSeat(vehicle, i) == ped) then return i end
    end
    return -1
end
exports('GetPedVehicleSeat', MSK.GetPedVehicleSeat)