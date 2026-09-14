local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Callbacks = {}        -- eventName -> { fn = handler, owner = resource }
local CallbackHandler = {}  -- requestId -> PENDING | NOT_FOUND | FAILED | packed results
local CallbackTarget = {}   -- requestId -> playerId the request was sent to (server only)

-- Milliseconds MSK.Trigger waits. Adjustable per server, on both sides:
--   setr msk:callbackTimeout 10000
local CALLBACK_TIMEOUT = GetConvarInt('msk:callbackTimeout', 5000)

local PENDING = 'request'
local NOT_FOUND = 'notFound'
local FAILED = 'failed'

--------------------------------------------------------------------------------
-- Request ids
--
-- A counter, not a random number. The old version drew math.random(1, 1e9) and
-- checked CallbackHandler[requestId] with that NUMBER, while the entry was
-- stored under tostring(requestId), a STRING. Number and string are different
-- keys in Lua, so the collision check looked at a slot that was never filled
-- and never caught anything. A counter cannot collide in the first place.
--
-- A counter is easy to guess, which is fine because an id alone proves
-- nothing: the server only accepts an answer from the player the request was
-- sent to (CallbackTarget). Server and client keep their own counters, an id
-- is only ever compared inside the resource that issued it.
--------------------------------------------------------------------------------
local requestCounter = 0

local function GenerateCallbackHandlerKey()
    requestCounter = requestCounter + 1
    return tostring(requestCounter)
end

local function traceback(err)
    return debug.traceback(tostring(err), 2)
end

--------------------------------------------------------------------------------
-- Registration
--
-- A callback belongs to the resource that registered it. Another resource
-- cannot silently replace it, and it is removed when its owner stops. Before
-- that, a stopped resource left its handler behind, the next call hit a dead
-- function reference, and the caller waited for an answer that never came.
--
-- `owner` is passed by the export wrapper in init/*.lua. Core code calls
-- Register without it and owns the callback as msk_core.
--------------------------------------------------------------------------------
local function registerCallback(eventName, cb, owner)
    assert(type(eventName) == 'string', 'Parameter "eventName" has to be a string on function MSK.Register')
    assert(cb ~= nil, ('Parameter "cb" is nil for callback "%s" on function MSK.Register'):format(eventName))

    owner = owner or GetCurrentResourceName()

    local existing = Callbacks[eventName]
    if existing and existing.owner ~= owner then
        MSK.Logging('error', ("Resource '%s' tried to register callback '%s', which already belongs to resource '%s'. The registration was ignored.")
            :format(owner, eventName, existing.owner))
        return false
    end

    Callbacks[eventName] = { fn = cb, owner = owner }
    return true
end

if IS_CORE then
    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then return end

        for eventName, entry in pairs(Callbacks) do
            if entry.owner == resource then
                Callbacks[eventName] = nil
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- Waiting for a response
--
-- Written once instead of three times (server Trigger, client Trigger, client
-- TriggerCallback). All three used to build a promise, reject it on timeout and
-- then return early without ever awaiting it, which left FiveM to report an
-- unhandled promise rejection for every callback that ran late. They also let
-- the timeout fire after a successful answer, where it cleared an entry that
-- had already been reused.
--
-- A caller now gets nil on timeout AND a line in the console saying which
-- callback did not answer, instead of a silent nil.
--------------------------------------------------------------------------------
--
-- `timeout` is in milliseconds; false waits without a limit. `playerId` (server
-- only) ends the wait as soon as that player has left, which is what keeps an
-- unlimited wait from hanging forever when someone disconnects mid-dialog.
local function awaitResponse(requestId, eventName, timeout, playerId)
    if timeout == nil then timeout = CALLBACK_TIMEOUT end

    local expired = false
    local playerLeft = false

    if timeout then
        SetTimeout(timeout, function()
            -- Only expire a request that is still waiting. After an answer the
            -- entry is gone, and clearing it again could hit a later request.
            if CallbackHandler[requestId] == PENDING then
                CallbackHandler[requestId] = nil
                expired = true
            end
        end)
    end

    local nextPlayerCheck = 0

    while CallbackHandler[requestId] == PENDING do
        if playerId and GetGameTimer() >= nextPlayerCheck then
            nextPlayerCheck = GetGameTimer() + 1000

            if not DoesPlayerExist(playerId) then
                CallbackHandler[requestId] = nil
                playerLeft = true
                break
            end
        end

        Wait(0)
    end

    local result = CallbackHandler[requestId]
    CallbackHandler[requestId] = nil
    CallbackTarget[requestId] = nil

    if playerLeft then
        -- Leaving while a dialog is open is normal, not an error.
        logging('debug', ("Callback '%s' ended, player %s left before answering."):format(eventName, playerId))
        return
    end

    if expired then
        MSK.Logging('error', ("Callback '%s' did not answer within %sms."):format(eventName, timeout))
        return
    end

    if result == NOT_FOUND then
        MSK.Logging('error', ("Callback '%s' is not registered on the other side."):format(eventName))
        return
    end

    if result == FAILED then
        -- The other side already printed the error with its stack trace.
        MSK.Logging('error', ("Callback '%s' raised an error on the other side, see its console."):format(eventName))
        return
    end

    if type(result) ~= 'table' then return end

    -- Unpacked with the stored count. `{ ... }` plus a plain table.unpack lost
    -- everything after a nil, so a handler returning `nil, 'busy'` arrived as
    -- nothing at all.
    return table.unpack(result, 1, result.n)
end

local Callback = {}
