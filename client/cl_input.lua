local isInputOpen = false
local callback = nil

MSK.Input = function(header, placeholder, field, cb)
    if isInputOpen then return end
    logging('debug', 'MSK.Input')
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
exports('Input', MSK.Input)
exports('openInput', MSK.Input) -- Support for old Scripts

MSK.CloseInput = function()
    logging('debug', 'MSK.CloseInput')
	isInputOpen = false
    callback = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeInput'
    })
end
exports('CloseInput', MSK.CloseInput)
exports('closeInput', MSK.CloseInput) -- Support for old Scripts
RegisterNetEvent('msk_core:closeInput', MSK.CloseInput)

MSK.Register('msk_core:input', function(source, header, placeholder, field)
    return MSK.Input(header, placeholder, field)
end)

RegisterNUICallback('submitInput', function(data)
    if data.input == '' then data.input = nil end
    if tonumber(data.input) then data.input = tonumber(data.input) end
	callback(data.input)
    MSK.CloseInput()
end)

RegisterNUICallback('closeInput', function(data)
    MSK.CloseInput()
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    MSK.CloseInput()
end)