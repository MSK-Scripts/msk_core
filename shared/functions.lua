MSK.GetConfig = function()
    return Config
end
exports('GetConfig', MSK.GetConfig)

local Timeouts = {}
local TimeoutId = 0
MSK.SetTimeout = function(ms, cb, data)
    assert(ms and tonumber(ms), 'Parameter "ms" has to be a number on function MSK.SetTimeout')
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
MSK.AddTimeout = MSK.SetTimeout -- Support for old Versions
exports('SetTimeout', MSK.SetTimeout)

MSK.ClearTimeout = function(requestId)
    assert(requestId, 'Parameter "requestId" is nil on function MSK.ClearTimeout')
    Timeouts[requestId] = true
end
MSK.DelTimeout = MSK.ClearTimeout -- Support for old Versions
exports('DelTimeout', MSK.ClearTimeout) -- Support for old Versions
exports('ClearTimeout', MSK.ClearTimeout)

MSK.Logging = function(code, ...)
    assert(code and type(code) == 'string', 'Parameter "code" has to be a string on function MSK.Logging')
    local script = ('[^2%s^0]'):format(GetInvokingResource() or 'msk_core')
    print(('%s %s'):format(script, Config.LoggingTypes[code] or Config.LoggingTypes['debug']), ...)
end
MSK.logging = MSK.Logging -- Support for old Versions
exports('Logging', MSK.Logging)

logging = function(code, ...)
    if not Config.Debug and code == 'debug' then return end
    MSK.Logging(code, ...)
end