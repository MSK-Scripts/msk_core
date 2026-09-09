-- The callback net-event listeners below are the shared msk_core responder and
-- must exist EXACTLY ONCE, inside msk_core itself. A consumer that eager-loads
-- this module would otherwise spin up a SECOND responder that answers
-- `callbackNotFound` for every other resource's callbacks and breaks them.
-- Consumers reach Register/Trigger through the export proxy instead
-- (exports.msk_core:Register / :Trigger / :TriggerCallback).
if IS_CORE then
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
        CallbackHandler[requestId] = 'request'

        TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, false, ...)

        return awaitResponse(requestId, eventName)
    end

    ---Triggers a server callback (cb method) and waits blocking for the response.
    ---@param eventName string
    ---@param ... any
    ---@return any ...
    function Callback.TriggerCallback(eventName, ...)
        local requestId = GenerateCallbackHandlerKey()
        CallbackHandler[requestId] = 'request'

        TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, true, ...)

        return awaitResponse(requestId, eventName)
    end
else
    -- Consumer view: route to the single responder inside msk_core.
    function Callback.Register(...) return exports.msk_core:Register(...) end
    function Callback.Trigger(...) return exports.msk_core:Trigger(...) end
    function Callback.TriggerCallback(...) return exports.msk_core:TriggerCallback(...) end
end

return Callback
