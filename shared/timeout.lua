MSK.Timeout = {}

local Timeouts = {}
local TimeoutId = 0

MSK.Timeout.Set = function(ms, cb, data)
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
MSK.SetTimeout = MSK.Timeout.Set -- Backwards compatibility
MSK.AddTimeout = MSK.Timeout.Set -- Backwards compatibility
exports('SetTimeout', MSK.SetTimeout)

setmetatable(MSK.Timeout, {
    __call = function(self, ...)
        return self.Set(...)
    end
})

MSK.Timeout.Clear = function(requestId)
    assert(requestId, 'Parameter "requestId" is nil on function MSK.Timeout.Clear')
    Timeouts[requestId] = true
end
MSK.ClearTimeout = MSK.Timeout.Clear -- Backwards compatibility
MSK.DelTimeout = MSK.Timeout.Clear -- Backwards compatibility
exports('ClearTimeout', MSK.Timeout.Clear)

-- Credits to ox_lib (https://overextended.dev/ox_lib/Modules/WaitFor/Shared)
MSK.Timeout.Await = function(timeout, cb, errMessage)
    local value = cb()

    if value ~= nil then return value end

    if timeout or timeout == nil then
        if type(timeout) ~= 'number' then timeout = 1000 end
    end

    local start = timeout and GetGameTimer()

    while value == nil do
        Wait(0)

        local elapsed = timeout and GetGameTimer() - start

        if elapsed and elapsed > timeout then
            return error(('%s (waited %.1fms)'):format(errMessage or 'failed to resolve callback', elapsed), 2)
        end

        value = cb()
    end

    return value
end
exports('AwaitTimeout', MSK.Timeout.Await)