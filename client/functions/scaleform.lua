MSK.Scaleform = {}

MSK.Scaleform.Show = function(scaleform, duration)
    if not scaleform then return end
    local draw = true

    MSK.Timeout.Set(duration or 5000, function()
        draw = false
    end)

    while draw do
        Wait(0)
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    end

    SetScaleformMovieAsNoLongerNeeded(scaleform)
end

MSK.Scaleform.FreemodeMessage = function(title, text, duration)
    local scaleform = MSK.Request.ScaleformMovie("MP_BIG_MESSAGE_FREEMODE")

    BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(text)
    EndScaleformMovieMethod()

    MSK.Scaleform.Show(scaleform, duration)
end
exports('FreemodeMessage', MSK.Scaleform.FreemodeMessage)
RegisterNetEvent("msk_core:freemodeMessage", MSK.Scaleform.FreemodeMessage)

MSK.Scaleform.PopupWarning = function(title, text, footer, duration)
    local scaleform = MSK.Request.ScaleformMovie("POPUP_WARNING")

    BeginScaleformMovieMethod(scaleform, "SHOW_POPUP_WARNING")
    ScaleformMovieMethodAddParamFloat(500.0) -- black background
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(text)
    ScaleformMovieMethodAddParamTextureNameString(footer)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    MSK.Scaleform.Show(scaleform, duration)
end
exports('PopupWarning', MSK.Scaleform.PopupWarning)
RegisterNetEvent("msk_core:popupWarning", MSK.Scaleform.PopupWarning)

MSK.Scaleform.BreakingNews = function(title, text, footer, duration)
    local scaleform = MSK.Request.ScaleformMovie("BREAKING_NEWS")

    BeginScaleformMovieMethod(scaleform, "SET_TEXT")
    ScaleformMovieMethodAddParamTextureNameString(text)
    ScaleformMovieMethodAddParamTextureNameString(footer)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "SET_SCROLL_TEXT")
    ScaleformMovieMethodAddParamInt(0) -- top ticker
    ScaleformMovieMethodAddParamInt(0) -- Since this is the first string, start at 0
    ScaleformMovieMethodAddParamTextureNameString(title)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "DISPLAY_SCROLL_TEXT")
    ScaleformMovieMethodAddParamInt(0) -- Top ticker
    ScaleformMovieMethodAddParamInt(0) -- Index of string
    EndScaleformMovieMethod()

    MSK.Scaleform.Show(scaleform, duration)
end
exports('BreakingNews', MSK.Scaleform.BreakingNews)
RegisterNetEvent("msk_core:breakingNews", MSK.Scaleform.BreakingNews)

MSK.Scaleform.TrafficMovie = function(duration)
    local scaleform = MSK.Request.ScaleformMovie("TRAFFIC_CAM")

    BeginScaleformMovieMethod(scaleform, "PLAY_CAM_MOVIE")
    EndScaleformMovieMethod()

    MSK.Scaleform.Show(scaleform, duration)
end
exports('TrafficMovie', MSK.Scaleform.TrafficMovie)
RegisterNetEvent("msk_core:trafficMovie", MSK.Scaleform.TrafficMovie)

-- Do NOT use this! Function is deprecated!
MSK.ScaleformAnnounce = function(title, text, typ, duration)
    if typ == 1 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.FreemodeMessage")
        MSK.Scaleform.FreemodeMessage(title, text, duration)
    elseif typ == 2 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.PopupWarning")
        MSK.Scaleform.PopupWarning(title, text, '', duration)
    end
end
exports('ScaleformAnnounce', MSK.ScaleformAnnounce)
RegisterNetEvent("msk_core:scaleformNotification", MSK.ScaleformAnnounce)