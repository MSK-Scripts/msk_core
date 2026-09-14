-- The callback net-event listeners below are the shared msk_core responder and
-- must exist EXACTLY ONCE, inside msk_core itself. A consumer that eager-loads
-- this module would otherwise spin up a SECOND responder that answers
-- `callbackNotFound` for every other resource's callbacks and breaks them.
-- Consumers reach Register/Trigger through the export proxy instead
-- (exports.msk_core:Register / exports.msk_core:Trigger).
if IS_CORE then
    ---Registers a server callback (triggerable from the client).
    ---@param eventName string
    ---@param cb function
    ---@param owner? string set by the export wrapper, core code leaves it out
    ---@return boolean registered
    function Callback.Register(eventName, cb, owner)
        return registerCallback(eventName, cb, owner)
    end

    local function failed(playerId, requestId, eventName, err)
        MSK.Logging('error', ("Callback '%s' raised an error for player %s: %s"):format(eventName, playerId, err))
        TriggerClientEvent('msk_core:client:callbackFailed', playerId, requestId)
    end

    -- Client triggers a registered server callback ([return] or [cb] method).
    -- The client picks the method. A client that lies about it only breaks its
    -- own request, and the handler runs protected either way.
    RegisterNetEvent('msk_core:server:triggerCallback', function(eventName, requestId, cbMethod, ...)
        local playerId = source
        local entry = type(eventName) == 'string' and Callbacks[eventName]

        if not entry then
            TriggerClientEvent('msk_core:client:callbackNotFound', playerId, requestId)
            return
        end

        if not cbMethod then
            -- Method [return]
            local results = table.pack(xpcall(entry.fn, traceback, playerId, ...))

            if not results[1] then
                return failed(playerId, requestId, eventName, results[2])
            end

            TriggerClientEvent("msk_core:client:callbackResponse", playerId, requestId, table.unpack(results, 2, results.n))
            return
        end

        -- Method [cb]. Only the first answer counts.
        local answered = false

        local ok, err = xpcall(entry.fn, traceback, playerId, function(...)
            if answered then return end
            answered = true
            TriggerClientEvent("msk_core:client:callbackResponse", playerId, requestId, ...)
        end, ...)

        if not ok and not answered then
            answered = true
            failed(playerId, requestId, eventName, err)
        end
    end)

    -- Answers are only accepted from the player the request went to. Without
    -- this check any client could answer or cancel another player's dialog,
    -- the counter based request ids are trivial to guess.
    local function isExpectedAnswer(requestId, playerId)
        return CallbackHandler[requestId] == PENDING and CallbackTarget[requestId] == playerId
    end

    RegisterNetEvent("msk_core:server:callbackResponse", function(requestId, ...)
        if not isExpectedAnswer(requestId, source) then return end
        CallbackHandler[requestId] = table.pack(...)
    end)

    RegisterNetEvent("msk_core:server:callbackNotFound", function(requestId)
        if not isExpectedAnswer(requestId, source) then return end
        CallbackHandler[requestId] = NOT_FOUND
    end)

    RegisterNetEvent("msk_core:server:callbackFailed", function(requestId)
        if not isExpectedAnswer(requestId, source) then return end
        CallbackHandler[requestId] = FAILED
    end)

    local function sendRequest(eventName, playerId, ...)
        local requestId = GenerateCallbackHandlerKey()
        CallbackHandler[requestId] = PENDING
        CallbackTarget[requestId] = playerId

        TriggerClientEvent('msk_core:client:triggerClientCallback', playerId, playerId, eventName, requestId, ...)

        return requestId
    end

    ---Triggers a client callback for `playerId` (server -> client) and waits blocking.
    ---@param eventName string
    ---@param playerId number
    ---@param ... any
    ---@return any ...
    function Callback.Trigger(eventName, playerId, ...)
        playerId = tonumber(playerId)

        -- Nobody there to answer, so do not wait five seconds for it.
        if not playerId or not DoesPlayerExist(playerId) then
            logging('debug', ("Callback '%s' was not sent, player %s does not exist."):format(eventName, tostring(playerId)))
            return
        end

        local requestId = sendRequest(eventName, playerId, ...)
        return awaitResponse(requestId, eventName)
    end

    ---Like Trigger, but for callbacks that wait on the player (dialogs, alerts,
    ---skillchecks), where the fixed 5 second limit of Trigger is far too short.
    ---`timeout` in milliseconds, or nil/false to wait until the player answers.
    ---Either way the wait ends when the player leaves, returning nil.
    ---@param eventName string
    ---@param playerId number
    ---@param timeout? number|false
    ---@param ... any
    ---@return any ...
    function Callback.TriggerAwait(eventName, playerId, timeout, ...)
        playerId = tonumber(playerId)

        if not playerId or not DoesPlayerExist(playerId) then
            logging('debug', ("Callback '%s' was not sent, player %s does not exist."):format(eventName, tostring(playerId)))
            return
        end

        local requestId = sendRequest(eventName, playerId, ...)
        return awaitResponse(requestId, eventName, tonumber(timeout) or false, playerId)
    end
    exports('TriggerAwait', Callback.TriggerAwait)
    MSK.TriggerAwait = Callback.TriggerAwait
else
    -- Consumer view: route to the single responder inside msk_core.
    function Callback.Register(eventName, cb) return exports.msk_core:Register(eventName, cb) end
    function Callback.Trigger(...) return exports.msk_core:Trigger(...) end
    function Callback.TriggerAwait(...) return exports.msk_core:TriggerAwait(...) end
end

return Callback
