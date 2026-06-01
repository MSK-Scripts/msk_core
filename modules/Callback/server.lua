---Registers a server callback (triggerable from the client).
---@param eventName string
---@param cb function
function Callback.Register(eventName, cb)
    Callbacks[eventName] = cb
end

-- Client triggers a registered server callback ([return] or [cb] method)
RegisterNetEvent('msk_core:server:triggerCallback', function(eventName, requestId, cb, ...)
    local playerId = source

    if not Callbacks[eventName] then
        TriggerClientEvent('msk_core:client:callbackNotFound', playerId, requestId)
        return
    end

    if not cb then
        -- Method [return]
        TriggerClientEvent("msk_core:client:callbackResponse", playerId, requestId, Callbacks[eventName](playerId, ...))
    else
        -- Method [cb]
        Callbacks[eventName](playerId, function(...)
            TriggerClientEvent("msk_core:client:callbackResponse", playerId, requestId, ...)
        end, ...)
    end
end)

RegisterNetEvent("msk_core:server:callbackResponse", function(requestId, ...)
    if not CallbackHandler[requestId] then return end
    CallbackHandler[requestId] = { ... }
end)

RegisterNetEvent("msk_core:server:callbackNotFound", function(requestId)
    if not CallbackHandler[requestId] then return end
    CallbackHandler[requestId] = nil
end)

---Triggers a client callback for `playerId` (server -> client) and waits blocking.
---@param eventName string
---@param playerId number
---@param ... any
---@return any ...
function Callback.Trigger(eventName, playerId, ...)
    local requestId = GenerateCallbackHandlerKey()
    local p = promise.new()
    CallbackHandler[requestId] = 'request'

    SetTimeout(5000, function()
        CallbackHandler[requestId] = nil
        p:reject(('Request Timed Out: [%s] [%s]'):format(eventName, requestId))
    end)

    TriggerClientEvent('msk_core:client:triggerClientCallback', playerId, playerId, eventName, requestId, ...)

    while CallbackHandler[requestId] == 'request' do Wait(0) end
    if not CallbackHandler[requestId] then return end

    p:resolve(CallbackHandler[requestId])
    CallbackHandler[requestId] = nil

    local result = Citizen.Await(p)
    return table.unpack(result)
end

return Callback
