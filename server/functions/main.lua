MSK.Notification = function(src, title, message, info, time)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:notification', src, title, message, info, time)
end
MSK.Notify = MSK.Notification
exports('Notification', MSK.Notification)

MSK.HelpNotification = function(src, text)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:helpNotification', src, text)
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)

MSK.AdvancedNotification = function(src, text, title, subtitle, icon, flash, icontype)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:advancedNotification', src, text, title, subtitle, icon, flash, icontype)
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)

MSK.ScaleformAnnounce = function(src, header, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:scaleformNotification', src, header, text, typ, duration)
end
MSK.Scaleform = MSK.ScaleformAnnounce
exports('ScaleformAnnounce', MSK.ScaleformAnnounce)

MSK.Subtitle = function(src, message, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:subtitle', src, message, duration)
end
exports('Subtitle', MSK.Subtitle)

MSK.Spinner = function(src, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:spinner', src, text, typ, duration)
end
exports('Spinner', MSK.Spinner)

MSK.Draw3DText = function(src, coords, text, size, font)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:draw3DText', src, coords, text, size, font)
end
exports('Draw3DText', MSK.Draw3DText)

MSK.DrawGenericText = function(src, text, outline, font, size, color, position)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:drawGenericText', src, text, outline, font, size, color, position)
end
exports('DrawGenericText', MSK.DrawGenericText)

MSK.IsSpawnPointClear = function(coords, maxDistance)
    if not coords then return end
    if not maxDistance then maxDistance = 5.0 end

    local nearbyVehicles = {}
    coords = vector3(coords.x, coords.y, coords.z)

    for k, vehicle in pairs(GetAllVehicles()) do
        local distance = #(coords - GetEntityCoords(vehicle))

        if distance <= maxDistance then
            nearbyVehicles[#nearbyVehicles + 1] = vehicle
        end
    end

    return #nearbyVehicles == 0
end
exports('IsSpawnPointClear', MSK.IsSpawnPointClear)

MSK.GetClosestPlayer = function(playerId, coords)
    return GetClosestEntity(playerId, coords)
end
exports('GetClosestPlayer', MSK.GetClosestPlayer)

MSK.GetClosestPlayers = function(playerId, coords, distance)
    return GetClosestEntities(playerId, coords, distance)
end
exports('GetClosestPlayers', MSK.GetClosestPlayers)

MSK.AddWebhook = function(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
    local content = {}

    if footer then 
        if time then
            footer = {
                ["text"] = footer.text .. " • " .. os.date(time),
                ["icon_url"] = footer.link
            }
        else
            footer = {
                ["text"] = footer.text,
                ["icon_url"] = footer.link
            }
        end
    end

    if fields then
        content = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = botColor,
            ["fields"] = fields,
            ["footer"] = footer
        }}
    else
        content = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = botColor,
            ["footer"] = footer
        }}
    end

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = botName,
        embeds = content,
        avatar_url = botAvatar
    }), {
        ['Content-Type'] = 'application/json'
    })
end
exports('AddWebhook', MSK.AddWebhook)

MSK.HasItem = function(playerId, item)
    if not playerId then 
        MSK.Logging('error', 'Player on Function MSK.HasItem does not exist!') 
        return
    end

    if MSK.Bridge.Framework.Type ~= 'ESX' and MSK.Bridge.Framework.Type ~= 'QBCore' then 
        MSK.Logging('error', ('Function %s can not used without Framework!'):format('^3MSK.HasItem^0'))
        return
    end

    local Player = MSK.GetPlayerFromId(playerId)
    
    return Player.HasItem(item)
end
exports('HasItem', MSK.HasItem)