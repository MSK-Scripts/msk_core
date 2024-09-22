MSK.GetClosestVehicle = function(coords)
    return GetClosestEntity(false, coords)
end
exports('GetClosestVehicle', MSK.GetClosestVehicle)

MSK.GetClosestVehicles = function(coords, distance)
    return GetClosestEntities(false, coords, distance)
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

MSK.GetVehicleInDirection = function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local inDirection = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(playerCoords, inDirection, 10, playerPed, 0)
    local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 and GetEntityType(entityHit) == 2 then
        local entityCoords = GetEntityCoords(entityHit)
        local entityDistance = #(playerCoords - entityCoords)
        return entityHit, entityCoords, entityDistance
    end

    return nil
end
exports('GetVehicleInDirection', MSK.GetVehicleInDirection)

MSK.GetPedVehicleSeat = function(ped, vehicle)
    if not ped then ped = PlayerPedId() end
    if not vehicle then GetVehiclePedIsIn(ped, false) end
    
    for i = -1, 16 do
        if (GetPedInVehicleSeat(vehicle, i) == ped) then return i end
    end
    return -1
end
exports('GetPedVehicleSeat', MSK.GetPedVehicleSeat)

MSK.IsVehicleEmpty = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

    return passengers == 0 and driverSeatFree
end
exports('IsVehicleEmpty', MSK.IsVehicleEmpty)

MSK.GetVehicleLabel = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function MSK.GetVehicleLabel')
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleLabel = GetDisplayNameFromVehicleModel(vehicleModel):lower()

    if not vehicleLabel or vehicleLabel == 'null' or vehicleLabel == 'carnotfound' then
        vehicleLabel = 'Unknown'
    else
        local labelText = GetLabelText(vehicleLabel)

        if labelText:lower() ~= 'null' then
            vehicleLabel = labelText
        end
    end

    return vehicleLabel
end
exports('GetVehicleLabel', MSK.GetVehicleLabel)

MSK.GetVehicleLabelFromModel = function(model)
    assert(model and IsModelValid(model), 'Parameter "model" is nil or the Model does not exist on function MSK.GetVehicleLabelFromModel')
    local vehicleLabel = GetDisplayNameFromVehicleModel(model):lower()

    if not vehicleLabel or vehicleLabel == 'null' or vehicleLabel == 'carnotfound' then
        vehicleLabel = 'Unknown'
    else
        local labelText = GetLabelText(vehicleLabel)

        if labelText:lower() ~= 'null' then
            vehicleLabel = labelText
        end
    end

    return vehicleLabel
end
exports('GetVehicleLabelFromModel', MSK.GetVehicleLabelFromModel)

MSK.CloseVehicleDoors = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function MSK.CloseVehicleDoors')

    for doorIndex = 0, 7 do
		if (DoesVehicleHaveDoor(vehicle, doorIndex) and GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0) then
			SetVehicleDoorShut(vehicle, doorIndex, false)
		end
	end
end
exports('CloseVehicleDoors', MSK.CloseVehicleDoors)

-- Credits to ESX Legacy (https://github.com/esx-framework/esx_core/blob/main/[core]/es_extended/client/modules/actions.lua)
local currentVehicle = {}
local isInVehicle, isEnteringVehicle = false, false
CreateThread(function()
	while true do
		local sleep = 200
		local playerPed = PlayerPedId()

		if not isInVehicle and not IsPlayerDead(PlayerId()) then
			if DoesEntityExist(GetVehiclePedIsTryingToEnter(playerPed)) and not isEnteringVehicle then
				local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
                local plate = GetVehicleNumberPlateText(vehicle)
                local seat = GetSeatPedIsTryingToEnter(playerPed)
				local netId = VehToNet(vehicle)
				local isEngineOn = Entity(vehicle).state.isEngineOn or GetIsVehicleEngineRunning(vehicle)
				local isDamaged = Entity(vehicle).state.isDamaged or false
				isEnteringVehicle = true
				TriggerEvent('msk_core:enteringVehicle', vehicle, plate, seat, netId, isEngineOn, isDamaged)
                TriggerServerEvent('msk_core:enteringVehicle', plate, seat, netId, isEngineOn, isDamaged)
			elseif not DoesEntityExist(GetVehiclePedIsTryingToEnter(playerPed)) and not IsPedInAnyVehicle(playerPed, true) and isEnteringVehicle then
				TriggerEvent('msk_core:enteringVehicleAborted')
                TriggerServerEvent('msk_core:enteringVehicleAborted')
                isEnteringVehicle = false
			elseif IsPedInAnyVehicle(playerPed, false) then
				isEnteringVehicle = false
                isInVehicle = true
				currentVehicle.vehicle = GetVehiclePedIsIn(playerPed)
				currentVehicle.plate = GetVehicleNumberPlateText(currentVehicle.vehicle)
				currentVehicle.seat = MSK.GetPedVehicleSeat(playerPed, currentVehicle.vehicle)
				currentVehicle.netId = VehToNet(currentVehicle.vehicle)
				currentVehicle.isEngineOn = Entity(currentVehicle.vehicle).state.isEngineOn or GetIsVehicleEngineRunning(currentVehicle.vehicle)
				currentVehicle.isDamaged = Entity(currentVehicle.vehicle).state.isDamaged or false
				TriggerEvent('msk_core:enteredVehicle', currentVehicle.vehicle, currentVehicle.plate, currentVehicle.seat, currentVehicle.netId, currentVehicle.isEngineOn, currentVehicle.isDamaged)
                TriggerServerEvent('msk_core:enteredVehicle', currentVehicle.plate, currentVehicle.seat, currentVehicle.netId, currentVehicle.isEngineOn, currentVehicle.isDamaged)
			end
		elseif isInVehicle then
			if not IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(PlayerId()) then
				isInVehicle = false
				TriggerEvent('msk_core:exitedVehicle', currentVehicle.vehicle, currentVehicle.plate, currentVehicle.seat, currentVehicle.netId, currentVehicle.isEngineOn, currentVehicle.isDamaged)
                TriggerServerEvent('msk_core:exitedVehicle', currentVehicle.plate, currentVehicle.seat, currentVehicle.netId, currentVehicle.isEngineOn, currentVehicle.isDamaged)
				currentVehicle = {}
			end
		end

		Wait(sleep)
	end
end)