--------------------------------------------------------------------------------
-- MSK.Numpad (client)
--
--   local ok, reason = MSK.Numpad.Open({
--       code = '0420',            -- a string, so leading zeros survive
--       masked = true,            -- show dots instead of digits (default true)
--       maxAttempts = 3,          -- optional, unlimited by default
--       title = 'Safe',
--       labels = { enter = 'Enter code', wrong = 'Wrong code', attempts = 'Attempts left' },
--   })
--   -- ok: true, or false with reason 'maxAttempts' | 'cancelled' | 'busy'
--   -- (a wrong code keeps the pad open, it does not return)
--
--   local digits = MSK.Numpad.Input({ length = 6, masked = true })   -- nil when cancelled
--
-- Both block, or take a callback as data.cb / second argument, which is called
-- in every case, cancel included.
--
-- The code never reaches the NUI: the NUI only knows the length and sends the
-- digits the player typed, the comparison happens here in Lua. On the client
-- the code still lives in the client's memory and the result is reported by
-- the client, which is fine for game mechanics. For anything of real value use
-- the server form MSK.Numpad.Open(playerId, { ... }), where the code never
-- leaves the server.
--
-- The old form MSK.Numpad(pin, showPin, cb) still works, but is deprecated.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Numpad = {}

if IS_CORE then
    local DEFAULT_LABELS = { enter = 'Enter Code', wrong = 'Incorrect', attempts = 'Attempts left' }

    local current = nil   -- { id, mode = 'code'|'input'|'remote', ... }
    local nextId = 0

    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" calls MSK.Numpad(pin, showPin, cb), which is deprecated and will be removed in a future version. Use MSK.Numpad.Open({ code = ..., masked = ... }) instead, or MSK.Numpad.Open(playerId, { ... }) on the server when the code protects anything of value.'):format(resource))
    end

    local function normalizeCode(value)
        local code = value ~= nil and tostring(value) or ''

        if not code:match('^%d+$') then
            error('MSK.Numpad: code has to consist of digits only (pass it as a string to keep leading zeros)', 3)
        end

        return code
    end

    local function labelsOf(labels)
        labels = type(labels) == 'table' and labels or {}
        return {
            enter = labels.enter or DEFAULT_LABELS.enter,
            wrong = labels.wrong or DEFAULT_LABELS.wrong,
            attempts = labels.attempts or DEFAULT_LABELS.attempts,
        }
    end

    -- What a numpad that did not succeed returns: nil for Input, false for
    -- Open. Written out on purpose: `mode == 'input' and nil or false` always
    -- yields false, because the nil in the middle makes the `or` take over.
    local function failedValue(state)
        if state.mode == 'input' then return nil end
        return false
    end

    local function finish(state, value, reason)
        if current ~= state then return end
        current = nil

        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeNumpad' })

        if state.cb then
            local ok, err = pcall(state.cb, value, reason)
            if not ok then
                MSK.Logging('error', ('MSK.Numpad callback of "%s" failed: %s'):format(tostring(state.owner), err))
            end
        end

        if state.promise then
            state.promise:resolve({ value, reason })
        end
    end

    -- Shows the numpad for `state`. Blocks and returns (value, reason) unless
    -- the state has a callback.
    local function begin(state)
        if current then
            if state.cb then
                pcall(state.cb, failedValue(state), 'busy')
                return
            end
            return failedValue(state), 'busy'
        end

        nextId = nextId + 1
        state.id = nextId
        current = state

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openNumpad',
            id = state.id,
            mode = state.mode == 'input' and 'input' or 'code',
            length = state.length,
            masked = state.masked,
            title = state.title,
            labels = state.labels,
        })

        if state.cb then return end

        state.promise = promise.new()
        local result = Citizen.Await(state.promise)
        return result[1], result[2]
    end

    ---@param data table (the pin, showPin, cb form is deprecated)
    ---@param cb? fun(ok: boolean, reason?: string)
    ---@return boolean? ok, string? reason
    function Numpad.Open(data, cb, legacyCb)
        local owner = GetInvokingResource() or 'msk_core'

        if type(data) ~= 'table' then
            warnDeprecated(owner)
            -- Old signature: (pin, showPin, cb)
            data = { code = data, masked = not cb, cb = legacyCb }
            cb = nil
        end

        local code = normalizeCode(data.code)

        return begin({
            mode = 'code',
            code = code,
            length = #code,
            masked = data.masked ~= false,
            maxAttempts = tonumber(data.maxAttempts),
            attempts = 0,
            title = data.title,
            labels = labelsOf(data.labels),
            cb = type(cb) == 'function' and cb or data.cb,
            owner = owner,
        })
    end
    MSK.OpenNumpad = Numpad.Open
    exports('Numpad', Numpad.Open)
    exports('OpenNumpad', Numpad.Open)

    ---Asks for digits without a code to compare against, e.g. for your own
    ---server-side check. Returns the digits as a string, or nil when cancelled.
    ---@param data? { length?: number, minLength?: number, masked?: boolean, title?: string, labels?: table, cb?: function }
    ---@param cb? fun(digits?: string, reason?: string)
    ---@return string? digits, string? reason
    function Numpad.Input(data, cb)
        data = type(data) == 'table' and data or {}

        return begin({
            mode = 'input',
            length = math.max(1, math.floor(tonumber(data.length) or 4)),
            minLength = math.max(1, math.floor(tonumber(data.minLength) or 1)),
            masked = data.masked == true,
            title = data.title,
            labels = labelsOf(data.labels),
            cb = type(cb) == 'function' and cb or data.cb,
            owner = GetInvokingResource() or 'msk_core',
        })
    end
    exports('NumpadInput', Numpad.Input)

    function Numpad.Close()
        local state = current
        if not state then return end

        finish(state, failedValue(state), 'cancelled')
    end
    MSK.CloseNumpad = Numpad.Close
    exports('CloseNumpad', Numpad.Close)
    RegisterNetEvent('msk_core:closeNumpad', Numpad.Close)

    ---@return boolean
    function Numpad.Active()
        return current ~= nil
    end
    exports('NumpadActive', Numpad.Active)

    -- Server-side Numpad.Open: the server keeps the code and checks every
    -- attempt itself; this side only collects the digits.
    MSK.Register('msk_core:numpadRemote', function(source, data)
        data = type(data) == 'table' and data or {}

        return begin({
            mode = 'remote',
            sessionId = data.session,
            length = math.max(1, math.floor(tonumber(data.length) or 4)),
            masked = data.masked ~= false,
            title = data.title,
            labels = labelsOf(data.labels),
            owner = 'msk_core',
        })
    end)

    MSK.Register('msk_core:numpadInput', function(source, data)
        return Numpad.Input(data)
    end)

    -- The NUI sends the typed digits and waits for this answer. Every path
    -- answers: an unanswered NUI request stays open forever.
    RegisterNUICallback('submitNumpad', function(data, cb)
        local state = current

        if not state or tonumber(data and data.id) ~= state.id then
            return cb({})
        end

        local input = type(data.input) == 'string' and data.input or ''
        local digitsOnly = input:match('^%d+$') ~= nil

        if state.mode == 'input' then
            if digitsOnly and #input >= state.minLength and #input <= state.length then
                cb({ ok = true })
                return finish(state, input, nil)
            end
            return cb({ ok = false })
        end

        if state.mode == 'remote' then
            local answer = digitsOnly and MSK.Trigger('msk_core:numpadVerify', state.sessionId, input) or { ok = false }

            if type(answer) ~= 'table' then
                cb({ ok = false, locked = true })
                return finish(state, false, 'error')
            end

            if answer.ok then
                cb({ ok = true })
                return finish(state, true, nil)
            end

            if answer.locked then
                cb({ ok = false, locked = true })
                return finish(state, false, 'maxAttempts')
            end

            if answer.done then
                cb({ ok = false, locked = true })
                return finish(state, false, 'error')
            end

            return cb({ ok = false, attemptsLeft = answer.attemptsLeft })
        end

        if digitsOnly and input == state.code then
            cb({ ok = true })
            return finish(state, true, nil)
        end

        state.attempts = state.attempts + 1

        if state.maxAttempts and state.attempts >= state.maxAttempts then
            cb({ ok = false, locked = true })
            return finish(state, false, 'maxAttempts')
        end

        cb({ ok = false, attemptsLeft = state.maxAttempts and (state.maxAttempts - state.attempts) or nil })
    end)

    RegisterNUICallback('closeNumpad', function(_, cb)
        cb('ok')
        Numpad.Close()
    end)

    AddEventHandler('onResourceStop', function(resource)
        if not current then return end

        if GetCurrentResourceName() == resource or current.owner == resource then
            Numpad.Close()
        end
    end)

    MSK.Numpad = setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Numpad
else
    function Numpad.Open(...) return exports.msk_core:Numpad(...) end
    function Numpad.Input(...) return exports.msk_core:NumpadInput(...) end
    function Numpad.Close() return exports.msk_core:CloseNumpad() end
    function Numpad.Active() return exports.msk_core:NumpadActive() end

    return setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
end
