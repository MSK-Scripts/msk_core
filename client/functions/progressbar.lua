MSK.Progress = {}

local isProgressOpen = false

MSK.Progress.Start = function(time, text, color)
    if isProgressOpen then
        MSK.Progress.Stop()
    end
    isProgressOpen = true

    SendNUIMessage({
        action = 'progressBarStart',
        time = time,
        text = text or '',
        color = color or Config.progressColor,
    })

    SetTimeout(time, function()
        isProgressOpen = false
    end)
end
MSK.Progressbar = MSK.Progress.Start -- Support for old Scripts
exports('Progressbar', MSK.Progress.Start)
exports('ProgressbarStart', MSK.Progress.Start) -- Support for old Scripts
RegisterNetEvent("msk_core:progressbar", MSK.Progress.Start)

MSK.Progress.Stop = function()
    SendNUIMessage({
        action = 'progressBarStop',
    })

    isProgressOpen = false
end
MSK.ProgressStop = MSK.Progress.Stop -- Support for old Scripts
exports('ProgressStop', MSK.Progress.Stop) -- Support for old Scripts
RegisterNetEvent("msk_core:progressbarStop", MSK.Progress.Stop)

MSK.Progress.Active = function()
    return isProgressOpen
end
exports('ProgressActive', MSK.Progress.Active)