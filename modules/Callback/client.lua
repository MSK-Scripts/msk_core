-- Receive the response resp. "not found" from the server
RegisterNetEvent("msk_core:client:callbackResponse", function(requestId, ...)
    if not CallbackHandler[requestId] then return end
    CallbackHandler[requestId] = { ... }
end)

RegisterNetEvent("msk_core:client:callbackNotFound", function(requestId)
    if not CallbackHandler[requestId] then return end
    CallbackHandler[requestId] = nil
end)

---Registers a client callback (triggerable from the server).
---@param eventName string
---@param cb function
function Callback.Register(eventName, cb)
    Callbacks[eventName] = cb
end

-- Server requests the execution of a registered client callback
RegisterNetEvent('msk_core:client:triggerClientCallback', function(playerId, eventName, requestId, ...)
    if not Callbacks[eventName] then
        TriggerServerEvent('msk_core:server:callbackNotFound', requestId)
        return
    end

    TriggerServerEvent("msk_core:server:callbackResponse", requestId, Callbacks[eventName](playerId, ...))
end)

---Triggers a server callback (return method) and waits blocking for the response.
---@param eventName string
---@param ... any
---@return any ...
function Callback.Trigger(eventName, ...)
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

---Triggers a server callback (cb method) and waits blocking for the response.
---@param eventName string
---@param ... any
---@return any ...
function Callback.TriggerCallback(eventName, ...)
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

return Callback
