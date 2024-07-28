MSK = {}

if Config.Framework == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()

    RegisterNetEvent('esx:setPlayerData', function(key, val)
        ESX.PlayerData[key] = val
    end)

    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        ESX.PlayerLoaded = false
        ESX.PlayerData = {}
    end)

    RegisterNetEvent('esx:setJob', function(job)
        ESX.PlayerData.job = job
    end)
elseif Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
        QBCore.PlayerData = PlayerData
    end)
end

exports('getCoreObject', function()
    return MSK
end)

MSK.Notification = function(title, message, typ, duration)
    if Config.Notification == 'native' then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    elseif Config.Notification == 'okok' then
        exports.okokNotify:Alert(title, message, duration or 5000, typ or 'info')
    elseif Config.Notification == 'custom' then
        Config.customNotification(title, message, typ or 'info', duration or 5000)
    else
        SendNUIMessage({
            action = 'notify',
            title = title,
            message = message,
            type = Config.NotifyTypes[typ] or {icon = 'fas fa-info-circle', color = '#75D6FF'},
            time = duration or 5000
        })
    end
end
MSK.Notify = MSK.Notification
exports('Notification', MSK.Notification)

MSK.HelpNotification = function(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)

MSK.AdvancedNotification = function(text, title, subtitle, icon, flash, icontype)
    if not flash then flash = true end
    if not icontype then icontype = 1 end
    if not icon then icon = 'CHAR_HUMANDEFAULT' end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostMessagetext(icon, icon, flash, icontype, title, subtitle)
	EndTextCommandThefeedPostTicker(false, true)
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)

MSK.ScaleformAnnounce = function(header, text, typ, duration)
    local scaleform = ''

    local loadScaleform = function(sclform)
        if not HasScaleformMovieLoaded(scaleform) then
            scaleform = RequestScaleformMovie(sclform)
            while not HasScaleformMovieLoaded(scaleform) do
                Wait(1)
            end
        end
    end

    if typ == 1 then
        loadScaleform("MP_BIG_MESSAGE_FREEMODE")
        BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
        ScaleformMovieMethodAddParamTextureNameString(header)
        ScaleformMovieMethodAddParamTextureNameString(text)
        EndScaleformMovieMethod()
    elseif typ == 2 then
        loadScaleform("POPUP_WARNING")
        BeginScaleformMovieMethod(scaleform, "SHOW_POPUP_WARNING")
        ScaleformMovieMethodAddParamFloat(500.0)
        ScaleformMovieMethodAddParamTextureNameString(header)
        ScaleformMovieMethodAddParamTextureNameString(text)
        EndScaleformMovieMethod()
    end

    local draw = true
    while draw do
        local sleep = 1

        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

        MSK.SetTimeout(duration or 8000, function()
            draw = false
        end)

        Wait(sleep)
    end
end
MSK.Scaleform = MSK.ScaleformAnnounce
exports('ScaleformAnnounce', MSK.ScaleformAnnounce)

MSK.Subtitle = function(text, duration)
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration or 8000, true)
end
exports('Subtitle', MSK.Subtitle)

MSK.Spinner = function(text, typ, duration)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandBusyspinnerOn(typ or 4) -- 4 or 5, all others are useless // 4 = orange // 5 = white

    MSK.SetTimeout(duration or 5000, function()
        BusyspinnerOff()
    end)
end
exports('Spinner', MSK.Spinner)

MSK.Draw3DText = function(coords, text, size, font)
    local coords = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetFinalRenderedCamCoord()
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
    if Config.Framework == 'standalone' then 
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

MSK.Progressbar = function(time, text, color)
    SendNUIMessage({
        action = 'progressBarStart',
        time = time,
        text = text or '',
        color = color or Config.progressColor,
    })
end
MSK.ProgressStart = MSK.Progressbar -- Support for old Scripts
exports('Progressbar', MSK.Progressbar)
exports('ProgressStart', MSK.Progressbar) -- Support for old Scripts

MSK.ProgressStop = function()
    SendNUIMessage({
        action = 'progressBarStop',
    })
end
exports('ProgressStop', MSK.ProgressStop)

RegisterNetEvent("msk_core:notification", function(title, message, typ, time)
    MSK.Notification(title, message, typ, time)
end)

RegisterNetEvent('msk_core:advancedNotification', function(text, title, subtitle, icon, flash, icontype)
    MSK.AdvancedNotification(text, title, subtitle, icon, flash, icontype)
end)

RegisterNetEvent("msk_core:scaleformNotification", function(title, message, typ, duration)
    MSK.ScaleformAnnounce(title, message, typ, duration)
end)

RegisterNetEvent("msk_core:subtitle", function(message, duration)
    MSK.Subtitle(message, duration)
end)

RegisterNetEvent("msk_core:spinner", function(text, typ, duration)
    MSK.Spinner(text, typ, duration)
end)