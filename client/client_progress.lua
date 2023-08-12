progressStart = function(text, time, color)
    SendNUIMessage({
        action = 'progressBarStart',
        text = text,
        time = time,
        color = color or '#5eb131',
    })
end
MSK.ProgressBar = progressStart
exports('ProgressBar', progressStart)

progressStop = function()
    SendNUIMessage({
        action = 'progressBarStop',
    })
end
MSK.ProgressStop = progressStop
exports('ProgressStop', progressStop)