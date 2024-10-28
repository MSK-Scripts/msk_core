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

MSK.GetVehicleInDirection = function(distance)
    local entity = MSK.Request.Raycast(distance, 2)

    if DoesEntityExist(entity) then
        local entityCoords = GetEntityCoords(entity)
        return entity, entityCoords, ('%.2f'):format(#(MSK.Player.coords - entityCoords))
    end

    return entity
end
MSK.GetVehicleInFront = MSK.GetVehicleInDirection
exports('GetVehicleInDirection', MSK.GetVehicleInDirection)

MSK.GetPedVehicleSeat = function(playerPed, vehicle)
    if not playerPed then playerPed = MSK.Player.ped end
    if not vehicle then vehicle = MSK.Player.vehicle end

    if not DoesEntityExist(vehicle) then return false end
    
    for i = -1, 16 do
        if GetPedInVehicleSeat(vehicle, i) == playerPed then 
            return i 
        end
    end

    return false
end
exports('GetPedVehicleSeat', MSK.GetPedVehicleSeat)

MSK.IsVehicleEmpty = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

    return passengers == 0 and driverSeatFree
end
exports('IsVehicleEmpty', MSK.IsVehicleEmpty)

MSK.GetVehicleLabel = function(vehicle, model)
    if not vehicle and not model then 
        return 'Unknown', error(('Paramters vehicle (%s) and model (%s) are not defined on function MSK.GetVehicleLabel'):format(vehicle, model))
    end
    
    local vehicleModel = nil

    if vehicle then
        if not DoesEntityExist(vehicle) then
            return 'Unknown', error(('The Vehicle does not exist on function MSK.GetVehicleLabel (reveived %s)'):format(vehicle))
        end

        vehicleModel = GetEntityModel(vehicle)
    end

    if model and not vehicleModel then
        if not IsModelValid(model) then
            return 'Unknown', error(('The Model does not exist on function MSK.GetVehicleLabel (reveived %s)'):format(model))
        end

        vehicleModel = model
    end

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
    assert(model, ('Parameter "model" is nil on function GetVehicleLabelFromModel (reveived %s)'):format(model))
    return MSK.GetVehicleLabel(nil, model)
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
		local playerPed = MSK.Player.ped

		if not isInVehicle and not IsPlayerDead(MSK.Player.clientId) then
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
			if not IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(MSK.Player.clientId) then
				isInVehicle = false
				TriggerEvent('msk_core:exitedVehicle', currentVehicle.vehicle, currentVehicle.plate, currentVehicle.seat, currentVehicle.netId, currentVehicle.isEngineOn, currentVehicle.isDamaged)
                TriggerServerEvent('msk_core:exitedVehicle', currentVehicle.plate, currentVehicle.seat, currentVehicle.netId, currentVehicle.isEngineOn, currentVehicle.isDamaged)
				currentVehicle = {}
			end
		end

		Wait(sleep)
	end
end)