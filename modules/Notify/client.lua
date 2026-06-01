function MSK.Notification(title, message, typ, duration)
    if Config.Notification == 'native' then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    elseif Config.Notification == 'okok' then
        exports.okokNotify:Alert(title, message, duration or 5000, typ or 'info')
    elseif Config.Notification == 'qb-core' then
        QBCore.Functions.Notify(message, typ, duration)
    elseif Config.Notification == 'bulletin' then
        exports.bulletin:Send({
            message = message,
            timeout = duration or 5000,
            theme = typ or 'info'
        })
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
exports('Notify', MSK.Notification)
RegisterNetEvent("msk_core:notification", MSK.Notification)

function MSK.HelpNotification(text, key)
    if Config.HelpNotification == 'native' then
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayHelp(0, false, true, -1)
    elseif Config.HelpNotification == 'custom' then
        Config.customHelpNotification(text)
    else
        MSK.TextUI.ShowThread(key, text)
    end
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)
exports('HelpNotify', MSK.HelpNotification)
RegisterNetEvent("msk_core:helpNotification", MSK.HelpNotification)

function MSK.AdvancedNotification(text, title, subtitle, icon, flash, icontype)
    if not flash then flash = true end
    if not icontype then icontype = 1 end
    if not icon then icon = 'CHAR_HUMANDEFAULT' end

    if Config.AdvancedNotification == 'bulletin' and GetResourceState('bulletin') == 'started' then
        exports.bulletin:SendAdvanced({
            message = text,
            title = title,
            subject = subtitle,
            icon = icon,
            timeout = 5000
        })
    elseif Config.AdvancedNotification == 'custom' then
        Config.customAdvancedNotification(text, title, subtitle, icon, flash, icontype)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandThefeedPostMessagetext(icon, icon, flash, icontype, title, subtitle)
        EndTextCommandThefeedPostTicker(false, true)
    end
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)
exports('AdvancedNotify', MSK.AdvancedNotification)
RegisterNetEvent("msk_core:advancedNotification", MSK.AdvancedNotification)

function MSK.Subtitle(text, duration)
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration or 8000, true)
end
exports('Subtitle', MSK.Subtitle)
RegisterNetEvent("msk_core:subtitle", MSK.Subtitle)

function MSK.Spinner(text, typ, duration)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandBusyspinnerOn(typ or 4) -- 4 = orange, 5 = white

    MSK.Timeout.Set(duration or 5000, function()
        BusyspinnerOff()
    end)
end
exports('Spinner', MSK.Spinner)
RegisterNetEvent("msk_core:spinner", MSK.Spinner)

function MSK.Draw3DText(coords, text, size, font)
    coords = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
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

function MSK.DrawGenericText(text, outline, font, size, color, position)
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

return true
