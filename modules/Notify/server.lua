-- One warning per resource, not per call.
local warnedResources = {}

local function warnDeprecated(resource)
    resource = resource or 'msk_core'
    if warnedResources[resource] then return end
    warnedResources[resource] = true

    MSK.Logging('warn', ('Resource "%s" calls MSK.Notification(playerId, title, message, type, duration), which is deprecated and will be removed in a future version. Pass a table instead: MSK.Notification(playerId, { title = ..., message = ..., type = ... })'):format(resource))
end

---Sends a notification to a player (-1 for everyone). The fields of the table
---are described in modules/Notify/client.lua.
---@param src number
---@param titleOrData table|string a table (the string form is deprecated)
function MSK.Notification(src, titleOrData, message, info, time)
    if not src or src == 0 then return end

    if type(titleOrData) ~= 'table' then
        warnDeprecated(GetInvokingResource())
        titleOrData = { title = titleOrData, message = message, type = info, duration = time }
    end

    TriggerClientEvent('msk_core:notification', src, titleOrData)
end
MSK.Notify = MSK.Notification
exports('Notification', MSK.Notification)
exports('Notify', MSK.Notification)

function MSK.HelpNotification(src, text)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:helpNotification', src, text)
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)
exports('HelpNotify', MSK.HelpNotification)

function MSK.AdvancedNotification(src, text, title, subtitle, icon, flash, icontype)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:advancedNotification', src, text, title, subtitle, icon, flash, icontype)
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)
exports('AdvancedNotify', MSK.AdvancedNotification)

function MSK.Subtitle(src, message, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:subtitle', src, message, duration)
end
exports('Subtitle', MSK.Subtitle)

function MSK.Spinner(src, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:spinner', src, text, typ, duration)
end
exports('Spinner', MSK.Spinner)

function MSK.Draw3DText(src, coords, text, size, font)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:draw3DText', src, coords, text, size, font)
end
exports('Draw3DText', MSK.Draw3DText)

function MSK.DrawGenericText(src, text, outline, font, size, color, position)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:drawGenericText', src, text, outline, font, size, color, position)
end
exports('DrawGenericText', MSK.DrawGenericText)

return true
