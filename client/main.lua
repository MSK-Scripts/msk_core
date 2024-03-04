MSK = {}

if Config.Framework:match('esx') then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework:match('qbcore') then
    QBCore = exports['qb-core']:GetCoreObject()
end

MSK.Notification = function(title, message, info, time)
    if Config.Notification == 'native' then
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    elseif Config.Notification == 'nui' or Config.Notification == 'msk' then
        SendNUIMessage({
            action = 'notify',
            title = title,
            message = message,
            info = info or 'general',
            time = time or 5000
        })
    elseif Config.Notification == 'okok' then
        exports['okokNotify']:Alert(title, message, time or 5000, info or 'info')
    end
end
exports('Notification', MSK.Notification)

MSK.HelpNotification = function(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end
exports('HelpNotification', MSK.HelpNotification)

MSK.AdvancedNotification = function(text, title, subtitle, icon, flash, icontype)
    if not flash then flash = true end
    if not icontype then icontype = 1 end
    if not icon then icon = 'CHAR_HUMANDEFAULT' end

    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    SetNotificationMessage(icon, icon, flash, icontype, title, subtitle)
	DrawNotification(false, true)
end
exports('AdvancedNotification', MSK.AdvancedNotification)

MSK.Draw3DText = function(coords, text, size, font)
    local coords = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)

    if not size then size = 1 end
    if not font then font = 0 end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, scale * 0.5)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end
exports('Draw3DText', MSK.Draw3DText)

MSK.HasItem = function(item)
    if not Config.Framework:match('esx') or not Config.Framework:match('qbcore') then 
        return logging('error', ('Function %s can not used without Framework!'):format('MSK.HasItem'))
    end

    local hasItem = MSK.Trigger('msk_core:hasItem', item)
    return hasItem
end
exports('HasItem', MSK.HasItem)

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

MSK.IsVehicleEmpty = function(vehicle)
    if not vehicle or (vehicle and not DoesEntityExist(vehicle)) then return end
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

    return passengers == 0 and driverSeatFree
end
exports('IsVehicleEmpty', MSK.IsVehicleEmpty)

MSK.GetPedMugshot = function(ped, transparent)
    if not DoesEntityExist(ped) then return end
    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end
exports('GetPedMugshot', MSK.GetPedMugshot)

RegisterNetEvent("msk_core:notification")
AddEventHandler("msk_core:notification", function(title, message, info, time)
    MSK.Notification(title, message, info, time)
end)

RegisterNetEvent('msk_core:advancedNotification')
AddEventHandler('msk_core:advancedNotification', function(text, title, subtitle, icon, flash, icontype)
    MSK.AdvancedNotification(text, title, subtitle, icon, flash, icontype)
end)

exports('getCoreObject', function()
    return MSK
end)