local isNumpadOpen = false
local callback = nil

MSK.Numpad = function(pin, show, cb)
    if isNumpadOpen then return end
    logging('debug', 'MSK.Numpad')
    isNumpadOpen = true
    callback = cb
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openNumpad',
        code = tostring(pin),
        length = string.len(tostring(pin)),
        show = show,
        EnterCode = 'Enter Code',
        WrongCode = 'Incorrect',
    })
end
exports('Numpad', MSK.Numpad)

MSK.CloseNumpad = function()
    logging('debug', 'MSK.CloseNumpad')
    isNumpadOpen = false
    callback = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeNumpad'
    })
end
exports('CloseNumpad', MSK.CloseNumpad)

RegisterNUICallback('submitNumpad', function(data)
    callback(true)
    MSK.CloseNumpad()
end)

RegisterNUICallback('closeNumpad', function()
    MSK.CloseNumpad()
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    MSK.CloseNumpad()
end)
  