--------------------------------------------------------------------------------
-- MSK.Numpad (server)
--
--   local ok, reason = MSK.Numpad.Open(playerId, { code = '0420', maxAttempts = 3, title = 'Vault' })
--   local digits = MSK.Numpad.Input(playerId, { length = 6 })
--
-- The code never leaves the server. The client shows the numpad and sends each
-- attempt here; this side compares, counts the attempts and decides. Whatever
-- the client reports as its own result is ignored.
--
-- ok is true, or false with reason 'maxAttempts' | 'cancelled' | 'busy' |
-- 'invalid'. The fields are described in modules/Numpad/client.lua.
--
-- The old form MSK.Numpad(playerId, pin, showPin) still works (and is now
-- checked on the server as well), but is deprecated.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Numpad = {}

if IS_CORE then
    local sessions = {}   -- [sessionId] = { playerId, code, attempts, maxAttempts, success, locked }
    local nextSession = 0

    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" calls MSK.Numpad(playerId, pin, showPin), which is deprecated and will be removed in a future version. Use MSK.Numpad.Open(playerId, { code = ..., masked = ... }) instead.'):format(resource))
    end

    local function normalizeCode(value)
        local code = value ~= nil and tostring(value) or ''

        if not code:match('^%d+$') then
            error('MSK.Numpad: code has to consist of digits only (pass it as a string to keep leading zeros)', 3)
        end

        return code
    end

    ---@param playerId number
    ---@param data table (the pin, showPin form is deprecated)
    ---@return boolean ok, string? reason
    function Numpad.Open(playerId, data, showPin)
        if not playerId or playerId <= 0 then return false, 'invalid' end

        if type(data) ~= 'table' then
            warnDeprecated(GetInvokingResource())
            data = { code = data, masked = not showPin }
        end

        local code = normalizeCode(data.code)

        nextSession = nextSession + 1
        local sessionId = nextSession
        local session = {
            playerId = playerId,
            code = code,
            attempts = 0,
            maxAttempts = tonumber(data.maxAttempts),
        }
        sessions[sessionId] = session

        -- TriggerAwait, not Trigger: typing takes longer than 5 seconds. The
        -- wait also ends when the player leaves.
        local _, reason = MSK.TriggerAwait('msk_core:numpadRemote', playerId, nil, {
            session = sessionId,
            length = #code,
            masked = data.masked ~= false,
            title = data.title,
            labels = data.labels,
        })

        sessions[sessionId] = nil

        if session.success then return true end
        if session.locked then return false, 'maxAttempts' end

        return false, reason == 'busy' and 'busy' or 'cancelled'
    end
    exports('Numpad', Numpad.Open)
    exports('OpenNumpad', Numpad.Open)

    -- Every attempt from the client ends up here. Only the player the session
    -- was opened for may answer it.
    MSK.Register('msk_core:numpadVerify', function(source, sessionId, input)
        local session = sessions[tonumber(sessionId)]

        if not session or session.playerId ~= source or session.success or session.locked then
            return { ok = false, done = true }
        end

        if type(input) == 'string' and input == session.code then
            session.success = true
            return { ok = true, done = true }
        end

        session.attempts = session.attempts + 1

        if session.maxAttempts and session.attempts >= session.maxAttempts then
            session.locked = true
            return { ok = false, done = true, locked = true }
        end

        return {
            ok = false,
            done = false,
            attemptsLeft = session.maxAttempts and (session.maxAttempts - session.attempts) or nil,
        }
    end)

    ---Asks a player for digits. The digits come from the client, check them
    ---yourself before trusting them.
    ---@param playerId number
    ---@param data? table
    ---@return string? digits, string? reason
    function Numpad.Input(playerId, data)
        if not playerId or playerId <= 0 then return nil, 'invalid' end

        data = type(data) == 'table' and data or {}
        local length = math.max(1, math.floor(tonumber(data.length) or 4))

        local digits, reason = MSK.TriggerAwait('msk_core:numpadInput', playerId, nil, data)

        if type(digits) ~= 'string' or not digits:match('^%d+$') or #digits > length then
            return nil, reason or 'cancelled'
        end

        return digits
    end
    exports('NumpadInput', Numpad.Input)

    function Numpad.Close(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:closeNumpad', playerId)
    end
    exports('CloseNumpad', Numpad.Close)

    MSK.Numpad = setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Numpad
else
    function Numpad.Open(...) return exports.msk_core:Numpad(...) end
    function Numpad.Input(...) return exports.msk_core:NumpadInput(...) end
    function Numpad.Close(...) return exports.msk_core:CloseNumpad(...) end

    return setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
end
