---Calls `fn` protected and waits (max. `timeout` ms, default 1000) for a result.
---@param fn fun(): any
---@param timeout? number
---@return any
return function(fn, timeout)
    return MSK.Timeout.Await(timeout or 1000, function()
        local ok, result = pcall(fn)
        if ok then return result end
    end)
end
