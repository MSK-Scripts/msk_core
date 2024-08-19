local Timeouts, Charset = {}, {}

for i = 48, 57 do table.insert(Charset, string.char(i)) end
for i = 65, 90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

MSK.GetRandomString = function(length)
    math.randomseed(GetGameTimer())

	return length > 0 and MSK.GetRandomString(length - 1) .. Charset[math.random(1, #Charset)] or ''
end
MSK.GetRandomLetter = MSK.GetRandomString -- Support for old Versions
exports('GetRandomString', MSK.GetRandomString)

MSK.GetConfig = function()
    return Config
end
exports('GetConfig', MSK.GetConfig)
exports('getConfig', MSK.GetConfig) -- Support for old Versions

MSK.Round = function(num, decimal)
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end
exports('Round', MSK.Round)

MSK.Trim = function(str, bool)
    if bool then return (str:gsub("^%s*(.-)%s*$", "%1")) end
    return (str:gsub("%s+", ""))
end
exports('Trim', MSK.Trim)

MSK.Split = function(str, delimiter)
    local result = {}
    
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do 
        table.insert(result, match) 
    end 

    return result 
end
exports('Split', MSK.Split)

MSK.TableContains = function(tbl, val)
    if not tbl then return end
    if not val then return end
    
    if type(val) == 'table' then
        for k, v in pairs(tbl) do
            for k2, v2 in pairs(val) do
                if v == v2 then
                    return true
                end
            end
        end
    else
        for k, v in pairs(tbl) do
            if v == val then
                return true
            end
        end
    end
    return false
end
MSK.Table_Contains = MSK.TableContains -- Support for old Versions
exports('TableContains', MSK.TableContains)

MSK.Comma = function(int, tag)
    if not tag then tag = '.' end
    local newInt = int

    while true do  
        newInt, k = string.gsub(newInt, "^(-?%d+)(%d%d%d)", '%1'..tag..'%2')

        if (k == 0) then
            break
        end
    end

    return newInt
end
exports('Comma', MSK.Comma)

local Timeout = 0
MSK.SetTimeout = function(ms, cb)
    local requestId = Timeout + 1

    SetTimeout(ms, function()
        if Timeouts[requestId] then 
            Timeouts[requestId] = nil 
            return 
        end

        cb()
    end)

    Timeout = requestId
    return requestId
end
MSK.AddTimeout = MSK.SetTimeout -- Support for old Versions
exports('SetTimeout', MSK.SetTimeout)

MSK.ClearTimeout = function(requestId)
    if not requestId then return end
    Timeouts[requestId] = true
end
MSK.DelTimeout = MSK.ClearTimeout -- Support for old Versions
exports('ClearTimeout', MSK.ClearTimeout)
exports('DelTimeout', MSK.ClearTimeout) -- Support for old Versions

MSK.DumpTable = function(tbl, n)
    if not n then n = 0 end
    if type(tbl) ~= "table" then return tostring(tbl) end
    local s = '{\n'

    for k, v in pairs(tbl) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        for i = 1, n, 1 do s = s .. "    " end
        s = s .. '    ['..k..'] = ' .. MSK.DumpTable(v, n + 1) .. ',\n'
    end

    for i = 1, n, 1 do s = s .. "    " end

    return s .. '}'
end
exports('DumpTable', MSK.DumpTable)

MSK.Logging = function(code, ...)
    local script = "[^2"..GetInvokingResource().."^0]"

    if not MSK.TableContains({'error', 'debug', 'info'}, code) then
        -- Support for old Versions
        script = code
        local action = ...
        local args = {...}
        table.remove(args, 1)

        print(script, Config.LoggingTypes[action], ...)
    else
        print(script, Config.LoggingTypes[code], ...)
    end
end
MSK.logging = MSK.Logging -- Support for old Versions
exports('Logging', MSK.Logging)

logging = function(code, ...)
    if not Config.Debug then return end
    print(Config.LoggingTypes[code], ...)
end