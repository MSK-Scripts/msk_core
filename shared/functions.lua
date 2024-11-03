MSK.Config = Config

MSK.GetConfig = function()
    return MSK.Config
end
exports('Config', MSK.GetConfig)
exports('GetConfig', MSK.GetConfig)

MSK.Call = function(fn, timeout)
    return MSK.Timeout.Await(timeout or 1000, function()
        local success, result = pcall(fn)

        if success then
            return result
        end
    end)
end

MSK.Logging = function(code, ...)
    assert(code and type(code) == 'string', 'Parameter "code" has to be a string on function MSK.Logging')
    print(('[^2%s^0] %s'):format(GetInvokingResource() or 'msk_core', Config.LoggingTypes[code] or Config.LoggingTypes['debug']), ..., '^0')
end
MSK.logging = MSK.Logging -- Backwards compatibility
exports('Logging', MSK.Logging)

logging = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end