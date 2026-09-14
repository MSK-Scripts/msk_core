---Calls `fn` protected and waits (max. `timeout` ms, default 1000) for a result.
---Returns nil when no result arrives in time, like MSK.Call inside msk_core
---(init/shared.lua). This version used to raise instead, so the same call
---failed softly in the core and ended the calling thread in every other script.
---@param fn fun(): any
---@param timeout? number
---@return any
return function(fn, timeout)
    local ok, result = pcall(MSK.Timeout.Await, timeout or 1000, function()
        local called, value = pcall(fn)
        if called then return value end
    end)

    if not ok then return nil end

    return result
end
