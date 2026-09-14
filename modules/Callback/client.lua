-- The callback net-event listeners below are the shared msk_core responder and
-- must exist EXACTLY ONCE, inside msk_core itself. A consumer that eager-loads
-- this module would otherwise spin up a SECOND responder that answers
-- `callbackNotFound` for every other resource's callbacks and breaks them.
-- Consumers reach Register/Trigger through the export proxy instead
-- (exports.msk_core:Register / :Trigger / :TriggerCallback).
if IS_CORE then
    -- Only the server sends these, a client cannot reach another client's
    -- events, so there is no source to check here.
    RegisterNetEvent("msk_core:client:callbackResponse", function(requestId, ...)
        if CallbackHandler[requestId] ~= PENDING then return end
        CallbackHandler[requestId] = table.pack(...)
    end)

    RegisterNetEvent("msk_core:client:callbackNotFound", function(requestId)
        if CallbackHandler[requestId] ~= PENDING then return end
        CallbackHandler[requestId] = NOT_FOUND
    end)

    RegisterNetEvent("msk_core:client:callbackFailed", function(requestId)
        if CallbackHandler[requestId] ~= PENDING then return end
        CallbackHandler[requestId] = FAILED
    end)

    ---Registers a client callback (triggerable from the server).
    ---@param eventName string
    ---@param cb function
    ---@param owner? string set by the export wrapper, core code leaves it out
    ---@return boolean registered
    function Callback.Register(eventName, cb, owner)
        return registerCallback(eventName, cb, owner)
    end

    -- Server requests the execution of a registered client callback
    RegisterNetEvent('msk_core:client:triggerClientCallback', function(playerId, eventName, requestId, ...)
        local entry = Callbacks[eventName]

        if not entry then
            TriggerServerEvent('msk_core:server:callbackNotFound', requestId)
            return
        end

        -- Protected, so an error answers at once instead of leaving the server
        -- waiting. With TriggerAwait that wait had no limit and lasted until
        -- the player disconnected.
        local results = table.pack(xpcall(entry.fn, traceback, playerId, ...))

        if not results[1] then
            MSK.Logging('error', ("Callback '%s' raised an error: %s"):format(eventName, results[2]))
            TriggerServerEvent('msk_core:server:callbackFailed', requestId)
            return
        end

        TriggerServerEvent("msk_core:server:callbackResponse", requestId, table.unpack(results, 2, results.n))
    end)

    ---Triggers a server callback (return method) and waits blocking for the response.
    ---@param eventName string
    ---@param ... any
    ---@return any ...
    function Callback.Trigger(eventName, ...)
        local requestId = GenerateCallbackHandlerKey()
        CallbackHandler[requestId] = PENDING

        TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, false, ...)

        return awaitResponse(requestId, eventName)
    end

    ---Triggers a server callback (cb method) and waits blocking for the response.
    ---@param eventName string
    ---@param ... any
    ---@return any ...
    function Callback.TriggerCallback(eventName, ...)
        local requestId = GenerateCallbackHandlerKey()
        CallbackHandler[requestId] = PENDING

        TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, true, ...)

        return awaitResponse(requestId, eventName)
    end

    ---Like Trigger, with its own time limit. For server callbacks that take
    ---longer than msk:callbackTimeout (database work, external requests).
    ---`timeout` in milliseconds, or nil/false to wait without a limit.
    ---@param eventName string
    ---@param timeout? number|false
    ---@param ... any
    ---@return any ...
    function Callback.TriggerAwait(eventName, timeout, ...)
        local requestId = GenerateCallbackHandlerKey()
        CallbackHandler[requestId] = PENDING

        TriggerServerEvent('msk_core:server:triggerCallback', eventName, requestId, false, ...)

        return awaitResponse(requestId, eventName, tonumber(timeout) or false)
    end
else
    -- Consumer view: route to the single responder inside msk_core.
    function Callback.Register(eventName, cb) return exports.msk_core:Register(eventName, cb) end
    function Callback.Trigger(...) return exports.msk_core:Trigger(...) end
    function Callback.TriggerCallback(...) return exports.msk_core:TriggerCallback(...) end
    function Callback.TriggerAwait(...) return exports.msk_core:TriggerAwait(...) end
end

return Callback
