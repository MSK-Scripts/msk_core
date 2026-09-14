local Scaleform = {}

function Scaleform.FreemodeMessage(playerId, title, text, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:freemodeMessage', playerId, title, text, duration)
end

function Scaleform.PopupWarning(playerId, title, text, footer, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:popupWarning', playerId, title, text, footer, duration)
end

function Scaleform.BreakingNews(playerId, title, text, footer, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:breakingNews', playerId, title, text, footer, duration)
end

function Scaleform.TrafficMovie(playerId, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:trafficMovie', playerId, duration)
end

-- Deprecated, kept for old scripts
local warnedResources = {}

function Scaleform.ScaleformAnnounce(playerId, title, text, typ, duration)
    -- Once per resource like the other deprecations, it used to log an error
    -- on every single call.
    local resource = GetInvokingResource() or GetCurrentResourceName()

    if not warnedResources[resource] then
        warnedResources[resource] = true
        MSK.Logging('warn', ('Resource "%s" calls MSK.ScaleformAnnounce, which is deprecated and will be removed in a future version. Use MSK.Scaleform.FreemodeMessage or MSK.Scaleform.PopupWarning instead.'):format(resource))
    end

    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:scaleformNotification', playerId, title, text, typ, duration)
end

return Scaleform
