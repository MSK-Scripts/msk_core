local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Numpad = {}

if IS_CORE then
    local isNumpadOpen = false
    local callback = nil

    -- Same reasoning as in the Input module: held apart from `callback` so that
    -- Close() can settle a waiting caller. Closing the numpad without entering
    -- a code left the promise unresolved, and a blocking MSK.Numpad(...) call
    -- waited forever, taking its thread with it.
    local pendingPromise = nil

    local function settle(value)
        local waiting = pendingPromise
        pendingPromise = nil

        if waiting then
            waiting:resolve(value)
        end
    end

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
            pendingPromise = p

            callback = function(response)
                settle(response)
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

        -- Anyone still waiting gets false, which reads as "code not entered".
        settle(false)

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
        -- The NUI can submit after the numpad was closed from Lua, leaving no
        -- callback to call. Calling it unchecked raised "attempt to call a nil
        -- value" out of a NUI callback.
        if callback then
            callback(true)
        end

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
