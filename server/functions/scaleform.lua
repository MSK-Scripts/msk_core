MSK.Scaleform = {}

MSK.Scaleform.FreemodeMessage = function(playerId, title, text, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:freemodeMessage', playerId, title, text, duration)
end
exports('FreemodeMessage', MSK.Scaleform.FreemodeMessage)

MSK.Scaleform.PopupWarning = function(playerId, title, text, footer, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:popupWarning', playerId, title, text, footer, duration)
end
exports('PopupWarning', MSK.Scaleform.PopupWarning)

MSK.Scaleform.BreakingNews = function(playerId, title, text, footer, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:breakingNews', playerId, title, text, footer, duration)
end
exports('BreakingNews', MSK.Scaleform.BreakingNews)

MSK.Scaleform.TrafficMovie = function(playerId, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:trafficMovie', playerId, duration)
end
exports('TrafficMovie', MSK.Scaleform.TrafficMovie)

-- Do NOT use this! Function is deprecated!
MSK.ScaleformAnnounce = function(playerId, title, text, typ, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:scaleformNotification', playerId, title, text, typ, duration)

    if typ == 1 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.FreemodeMessage")
    elseif typ == 2 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.PopupWarning")
    end
end
exports('ScaleformAnnounce', MSK.ScaleformAnnounce)