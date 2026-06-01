local Timeout = {}

local Timeouts = {}
local TimeoutId = 0

---Schedules `cb(data)` after `ms` milliseconds. Returns: requestId (for Clear).
---@param ms number
---@param cb fun(data: any)
---@param data? any
---@return number requestId
function Timeout.Set(ms, cb, data)
    assert(ms and tonumber(ms), 'Parameter "ms" has to be a number on function MSK.Timeout.Set')
    local requestId = TimeoutId + 1

    SetTimeout(ms, function()
        if Timeouts[requestId] then
            Timeouts[requestId] = nil
            return
        end

        cb(data)
    end)

    TimeoutId = requestId
    return requestId
end

---Cancels a scheduled timeout (by requestId).
---@param requestId number
function Timeout.Clear(requestId)
    assert(requestId, 'Parameter "requestId" is nil on function MSK.Timeout.Clear')
    Timeouts[requestId] = true
end

-- Polling pattern inspired by ox_lib (WaitFor), implemented independently here.
---Waits (polling) until `cb` returns a non-nil value.
---Time-limit semantics: number = this limit (ms);
---nil/other truthy = 1000 ms; explicit `false` = no limit.
---@param timeout? number|boolean
---@param cb fun(): any
---@param errMessage? string
---@return any
function Timeout.Await(timeout, cb, errMessage)
    if timeout ~= false and type(timeout) ~= 'number' then
        timeout = 1000
    end

    local value = cb()
    if value ~= nil then return value end

    local startedAt = timeout and GetGameTimer()
    while value == nil do
        Wait(0)

        if timeout then
            local elapsed = GetGameTimer() - startedAt
            if elapsed > timeout then
                return error(('%s (waited %.1fms)'):format(errMessage or 'failed to resolve callback', elapsed), 2)
            end
        end

        value = cb()
    end

    return value
end

-- MSK.Timeout(ms, cb, data) -> Set
return setmetatable(Timeout, {
    __call = function(self, ...)
        return self.Set(...)
    end
})
