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

-- Deprecated (kept only for legacy)
function Scaleform.ScaleformAnnounce(playerId, title, text, typ, duration)
    if not playerId or playerId == 0 then return end
    TriggerClientEvent('msk_core:scaleformNotification', playerId, title, text, typ, duration)

    if typ == 1 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.FreemodeMessage")
    elseif typ == 2 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.PopupWarning")
    end
end

return Scaleform
