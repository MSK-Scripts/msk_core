local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Input = {}

if IS_CORE then
    local isInputOpen = false
    local callback = nil

    function Input.Open(header, placeholder, field, cb)
        if isInputOpen then return end
        isInputOpen = true
        callback = cb
        if not callback then callback = field end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openInput",
            header = header,
            placeholder = placeholder,
            field = field and type(field) == 'boolean'
        })

        if not callback or callback and type(callback) == 'boolean' then
            local p = promise.new()

            callback = function(response)
                p:resolve(response)
            end

            return Citizen.Await(p)
        end
    end
    MSK.OpenInput = Input.Open
    exports('Input', Input.Open)
    exports('OpenInput', Input.Open)

    function Input.Close()
        isInputOpen = false
        callback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeInput' })
    end
    MSK.CloseInput = Input.Close -- Backwards compatibility
    exports('CloseInput', Input.Close)
    RegisterNetEvent('msk_core:closeInput', Input.Close)

    MSK.Register('msk_core:input', function(source, header, placeholder, field)
        return Input.Open(header, placeholder, field)
    end)

    function Input.Active()
        return isInputOpen
    end
    exports('InputActive', Input.Active)

    RegisterNUICallback('submitInput', function(data)
        if data.input == '' then data.input = nil end
        if tonumber(data.input) then data.input = tonumber(data.input) end
        callback(data.input)
        Input.Close()
    end)

    RegisterNUICallback('closeInput', function()
        Input.Close()
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        Input.Close()
    end)

    MSK.Input = setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Input
else
    function Input.Open(...) return exports.msk_core:Input(...) end
    function Input.Close() return exports.msk_core:CloseInput() end
    function Input.Active() return exports.msk_core:InputActive() end

    return setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
end
