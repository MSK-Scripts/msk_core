local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Scaleform = {}

function Scaleform.Show(scaleform, duration)
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

function Scaleform.FreemodeMessage(title, text, duration)
    local scaleform = MSK.Request.ScaleformMovie("MP_BIG_MESSAGE_FREEMODE")

    BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(text)
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

function Scaleform.PopupWarning(title, text, footer, duration)
    local scaleform = MSK.Request.ScaleformMovie("POPUP_WARNING")

    BeginScaleformMovieMethod(scaleform, "SHOW_POPUP_WARNING")
    ScaleformMovieMethodAddParamFloat(500.0) -- black background
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(text)
    ScaleformMovieMethodAddParamTextureNameString(footer)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

function Scaleform.BreakingNews(title, text, footer, duration)
    local scaleform = MSK.Request.ScaleformMovie("BREAKING_NEWS")

    BeginScaleformMovieMethod(scaleform, "SET_TEXT")
    ScaleformMovieMethodAddParamTextureNameString(text)
    ScaleformMovieMethodAddParamTextureNameString(footer)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "SET_SCROLL_TEXT")
    ScaleformMovieMethodAddParamInt(0) -- top ticker
    ScaleformMovieMethodAddParamInt(0) -- first string -> start at 0
    ScaleformMovieMethodAddParamTextureNameString(title)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "DISPLAY_SCROLL_TEXT")
    ScaleformMovieMethodAddParamInt(0) -- Top ticker
    ScaleformMovieMethodAddParamInt(0) -- Index of string
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

function Scaleform.TrafficMovie(duration)
    local scaleform = MSK.Request.ScaleformMovie("TRAFFIC_CAM")

    BeginScaleformMovieMethod(scaleform, "PLAY_CAM_MOVIE")
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

-- Deprecated (kept only for legacy) — MSK.ScaleformAnnounce
function Scaleform.ScaleformAnnounce(title, text, typ, duration)
    if typ == 1 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.FreemodeMessage")
        Scaleform.FreemodeMessage(title, text, duration)
    elseif typ == 2 then
        MSK.Logging('error', "function MSK.ScaleformAnnounce is deprecated! Please use MSK.Scaleform.PopupWarning")
        Scaleform.PopupWarning(title, text, '', duration)
    end
end

if IS_CORE then
    RegisterNetEvent("msk_core:freemodeMessage", Scaleform.FreemodeMessage)
    RegisterNetEvent("msk_core:popupWarning", Scaleform.PopupWarning)
    RegisterNetEvent("msk_core:breakingNews", Scaleform.BreakingNews)
    RegisterNetEvent("msk_core:trafficMovie", Scaleform.TrafficMovie)
    RegisterNetEvent("msk_core:scaleformNotification", Scaleform.ScaleformAnnounce)
end

return Scaleform
