local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Callbacks = {}        -- eventName -> handler function
local CallbackHandler = {}  -- requestId -> 'request' | { result... } | nil

local CALLBACK_TIMEOUT = 5000

--------------------------------------------------------------------------------
-- Request ids
--
-- A counter, not a random number. The old version drew math.random(1, 1e9) and
-- checked CallbackHandler[requestId] with that NUMBER, while the entry was
-- stored under tostring(requestId), a STRING. Number and string are different
-- keys in Lua, so the collision check looked at a slot that was never filled
-- and never caught anything. A counter cannot collide in the first place.
--
-- Server and client keep their own counters, which is fine: an id is only ever
-- compared inside the resource that issued it.
--------------------------------------------------------------------------------
local requestCounter = 0

local function GenerateCallbackHandlerKey()
    requestCounter = requestCounter + 1
    return tostring(requestCounter)
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
local function awaitResponse(requestId, eventName)
    local expired = false

    SetTimeout(CALLBACK_TIMEOUT, function()
        -- Only expire a request that is still waiting. After an answer the
        -- entry is gone, and clearing it again could hit a later request.
        if CallbackHandler[requestId] == 'request' then
            CallbackHandler[requestId] = nil
            expired = true
        end
    end)

    while CallbackHandler[requestId] == 'request' do
        Wait(0)
    end

    local result = CallbackHandler[requestId]
    CallbackHandler[requestId] = nil

    if expired then
        MSK.Logging('error', ("Callback '%s' did not answer within %sms."):format(eventName, CALLBACK_TIMEOUT))
        return
    end

    if type(result) ~= 'table' then
        -- The other side reported the callback as unknown.
        MSK.Logging('error', ("Callback '%s' is not registered on the other side."):format(eventName))
        return
    end

    return table.unpack(result)
end

local Callback = {}
