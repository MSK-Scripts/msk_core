local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Numpad = {}

if IS_CORE then
    local isNumpadOpen = false
    local callback = nil

    function Numpad.Open(pin, showPin, cb)
        if isNumpadOpen then return end
        isNumpadOpen = true
        callback = cb

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openNumpad',
            code = tostring(pin),
            length = string.len(tostring(pin)),
            show = showPin,
            EnterCode = 'Enter Code',
            WrongCode = 'Incorrect',
        })

        if not callback then
            local p = promise.new()

            callback = function(response)
                p:resolve(response)
            end

            return Citizen.Await(p)
        end
    end
    MSK.OpenNumpad = Numpad.Open
    exports('Numpad', Numpad.Open)
    exports('OpenNumpad', Numpad.Open)

    function Numpad.Close()
        isNumpadOpen = false
        callback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeNumpad' })
    end
    MSK.CloseNumpad = Numpad.Close
    exports('CloseNumpad', Numpad.Close)
    RegisterNetEvent('msk_core:closeNumpad', Numpad.Close)

    MSK.Register('msk_core:numpad', function(source, pin, showPin)
        return Numpad.Open(pin, showPin)
    end)

    function Numpad.Active()
        return isNumpadOpen
    end
    exports('NumpadActive', Numpad.Active)

    RegisterNUICallback('submitNumpad', function(data)
        callback(true)
        Numpad.Close()
    end)

    RegisterNUICallback('closeNumpad', function()
        Numpad.Close()
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        Numpad.Close()
    end)

    MSK.Numpad = setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Numpad
else
    function Numpad.Open(...) return exports.msk_core:Numpad(...) end
    function Numpad.Close() return exports.msk_core:CloseNumpad() end
    function Numpad.Active() return exports.msk_core:NumpadActive() end

    return setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
end
