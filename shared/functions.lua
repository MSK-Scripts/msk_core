MSK.GetConfig = function()
    return Config
end
exports('GetConfig', MSK.GetConfig)
exports('Config', MSK.GetConfig)

MSK.Logging = function(code, ...)
    assert(code and type(code) == 'string', 'Parameter "code" has to be a string on function MSK.Logging')
    print(('%s %s'):format(('[^2%s^0]'):format(GetInvokingResource() or 'msk_core'), Config.LoggingTypes[code] or Config.LoggingTypes['debug']), ..., '^0')
end
MSK.logging = MSK.Logging -- Support for old Versions
exports('Logging', MSK.Logging)

logging = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end