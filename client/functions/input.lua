MSK.Input = {}

local isInputOpen = false
local callback = nil

MSK.Input.Open = function(header, placeholder, field, cb)
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

        local result = Citizen.Await(p)
        return result
    end
end
MSK.OpenInput = MSK.Input.Open
exports('Input', MSK.Input.Open)

setmetatable(MSK.Input, {
    __call = function(self, ...)
        self.Open(...)
    end
})

MSK.Input.Close = function()
	isInputOpen = false
    callback = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeInput'
    })
end
MSK.CloseInput = MSK.Input.Close -- Backwards compatibility
exports('CloseInput', MSK.Input.Close)
RegisterNetEvent('msk_core:closeInput', MSK.Input.Close)

MSK.Register('msk_core:input', function(source, header, placeholder, field)
    return MSK.Input.Open(header, placeholder, field)
end)

MSK.Input.Active = function()
    return isInputOpen
end
exports('InputActive', MSK.Input.Active)

RegisterNUICallback('submitInput', function(data)
    if data.input == '' then data.input = nil end
    if tonumber(data.input) then data.input = tonumber(data.input) end
	callback(data.input)
    MSK.Input.Close()
end)

RegisterNUICallback('closeInput', function(data)
    MSK.Input.Close()
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    MSK.Input.Close()
end)