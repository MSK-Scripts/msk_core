local Callbacks = {}
local CallbackHandler = {}

local GenerateCallbackHandlerKey = function()
    local requestId = math.random(1, 999999999)

    if not CallbackHandler[requestId] then 
        return tostring(requestId)
    else
        GenerateCallbackHandlerKey()
    end
end

RegisterNetEvent("msk_core:client:callbackResponse", function(requestId, ...)
	if not CallbackHandler[requestId] then return end
	CallbackHandler[requestId] = {...}
end)

RegisterNetEvent("msk_core:client:callbackNotFound", function(requestId)
	if not CallbackHandler[requestId] then return end
	CallbackHandler[requestId] = nil
end)

----------------------------------------------------------------
-- Client Callbacks
----------------------------------------------------------------
MSK.Register = function(eventName, cb)
    Callbacks[eventName] = cb
end
MSK.RegisterCallback = MSK.Register
MSK.RegisterClientCallback = MSK.Register
exports('Register', MSK.Register)
exports('RegisterCallback', MSK.Register)
exports('RegisterServerCallback', MSK.Register)

RegisterNetEvent('msk_core:client:triggerClientCallback', function(playerId, eventName, requestId, ...)
    if not Callbacks[eventName] then 
        TriggerServerEvent('msk_core:server:callbackNotFound', requestId)
        return
    end

    TriggerServerEvent("msk_core:server:callbackResponse", requestId, Callbacks[eventName](playerId, ...))
end)

----------------------------------------------------------------
-- Server Callbacks with Method [return]
----------------------------------------------------------------
MSK.Trigger = function(eventName, ...)
    local requestId = GenerateCallbackHandlerKey()
    local p = promise.new()
    CallbackHandler[requestId] = 'request'

    SetTimeout(5000, function()
        CallbackHandler[requestId] = nil
        p:reject(('Request Timed Out: [%s] [%s]'):format(eventName, requestId))
    end)

    TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, false, ...)

    while CallbackHandler[requestId] == 'request' do Wait(0) end
    if not CallbackHandler[requestId] then return end

    p:resolve(CallbackHandler[requestId])
    CallbackHandler[requestId] = nil

    local result = Citizen.Await(p)
    return table.unpack(result)
end
exports('Trigger', MSK.Trigger)

----------------------------------------------------------------
-- Server Callbacks with Method [cb]
----------------------------------------------------------------
MSK.TriggerCallback = function(eventName, ...)
    local requestId = GenerateCallbackHandlerKey()
    local p = promise.new()
    CallbackHandler[requestId] = 'request'

    SetTimeout(5000, function()
        CallbackHandler[requestId] = nil
        p:reject(('Request Timed Out: [%s] [%s]'):format(eventName, requestId))
    end)
    
    TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, true, ...)

    while CallbackHandler[requestId] == 'request' do Wait(0) end
    if not CallbackHandler[requestId] then return end

    p:resolve(CallbackHandler[requestId])
    CallbackHandler[requestId] = nil

    local result = Citizen.Await(p)
    return table.unpack(result)
end
MSK.TriggerServerCallback = MSK.TriggerCallback
exports('TriggerCallback', MSK.TriggerCallback)
exports('TriggerServerCallback', MSK.TriggerCallback)