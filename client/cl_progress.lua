MSK.Progressbar = function(time, text, color)
    SendNUIMessage({
        action = 'progressBarStart',
        time = time,
        text = text or '',
        color = color or Config.progressColor,
    })
end
MSK.ProgressStart = MSK.Progressbar
exports('Progressbar', MSK.Progressbar)
exports('ProgressStart', MSK.Progressbar)

MSK.ProgressStop = function()
    SendNUIMessage({
        action = 'progressBarStop',
    })
end
exports('ProgressStop', MSK.ProgressStop)