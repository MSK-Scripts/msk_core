MSK.Notification = function(title, message, typ, duration)
    if Config.Notification == 'native' then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    elseif Config.Notification == 'okok' then
        exports.okokNotify:Alert(title, message, duration or 5000, typ or 'info')
    elseif Config.Notification == 'qb-core' then
        QBCore.Functions.Notify(message, typ, duration)
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
RegisterNetEvent("msk_core:notification", MSK.Notification)

MSK.HelpNotification = function(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)
RegisterNetEvent("msk_core:helpNotification", MSK.HelpNotification)

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
RegisterNetEvent("msk_core:advancedNotification", MSK.AdvancedNotification)

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
RegisterNetEvent("msk_core:scaleformNotification", MSK.ScaleformAnnounce)

MSK.Subtitle = function(text, duration)
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration or 8000, true)
end
exports('Subtitle', MSK.Subtitle)
RegisterNetEvent("msk_core:subtitle", MSK.Subtitle)

MSK.Spinner = function(text, typ, duration)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandBusyspinnerOn(typ or 4) -- 4 or 5, all others are useless // 4 = orange // 5 = white

    MSK.SetTimeout(duration or 5000, function()
        BusyspinnerOff()
    end)
end
exports('Spinner', MSK.Spinner)
RegisterNetEvent("msk_core:spinner", MSK.Spinner)

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
RegisterNetEvent("msk_core:draw3DText", MSK.Draw3DText)

MSK.DrawGenericText = function(text, outline, font, size, color, position)
    if not font then font = 0 end
    if not size then size = 0.34 end
    if not color then color = {r = 255, g = 255, b = 255, a = 255} end
    if not position then position = {width = 0.50, height = 0.90} end

	SetTextColour(color.r, color.g, color.b, color.a)
	SetTextFont(font)
	SetTextScale(size, size)
	SetTextWrap(0.0, 1.0)
	SetTextCentre(true)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 205)
    if outline then SetTextOutline() end
	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(position.width, position.height)
end
exports('DrawGenericText', MSK.DrawGenericText)
RegisterNetEvent("msk_core:drawGenericText", MSK.DrawGenericText)

MSK.HasItem = function(item)
    if MSK.Bridge.Framework.Type ~= 'ESX' and MSK.Bridge.Framework.Type ~= 'QBCore' then 
        logging('error', ('Function %s can not used without Framework!'):format('MSK.HasItem'))
        return
    end

    return MSK.Trigger('msk_core:hasItem', item)
end
exports('HasItem', MSK.HasItem)

MSK.IsSpawnPointClear = function(coords, maxDistance)
    local nearbyVehicles = {}

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        coords = GetEntityCoords(PlayerPedId())
    end

    for k, vehicle in pairs(GetGamePool('CVehicle')) do
        local distance = #(coords - GetEntityCoords(vehicle))

        if distance <= maxDistance then
            nearbyVehicles[#nearbyVehicles + 1] = vehicle
        end
    end

    return #nearbyVehicles == 0
end
exports('IsSpawnPointClear', MSK.IsSpawnPointClear)

MSK.GetPedMugshot = function(ped, transparent)
    assert(ped and DoesEntityExist(ped), 'Parameter "ped" is nil or the PlayerPed does not exist')
    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end
exports('GetPedMugshot', MSK.GetPedMugshot)

MSK.LoadAnimDict = function(dict)
    assert(dict and DoesAnimDictExist(dict), 'Parameter "dict" is nil or the AnimDict does not exist')

    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Wait(1)
        end
    end
end
exports('LoadAnimDict', MSK.LoadAnimDict)

MSK.LoadModel = function(modelHash)
    assert(modelHash and IsModelValid(modelHash), 'Parameter "modelHash" is nil or the Model does not exist')

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
    
        while not HasModelLoaded(modelHash) do
            Wait(1)
        end
    end
end
exports('LoadModel', MSK.LoadModel)

MSK.GetClosestPlayer = function(coords)
    return GetClosestEntity(true, coords)
end
exports('GetClosestPlayer', MSK.GetClosestPlayer)

MSK.GetClosestPlayers = function(coords, distance)
    return GetClosestEntities(true, coords, distance)
end
exports('GetClosestPlayers', MSK.GetClosestPlayers)