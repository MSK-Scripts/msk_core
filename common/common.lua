local Timeouts, Letters = {}, {}

for i = 48, 57 do table.insert(Letters, string.char(i)) end
for i = 65, 90 do table.insert(Letters, string.char(i)) end
for i = 97, 122 do table.insert(Letters, string.char(i)) end

MSK.GetRandomString = function(length)
    Wait(0)
    if length > 0 then
        return MSK.GetRandomString(length - 1) .. Letters[math.random(1, #Letters)]
    else
        return ''
    end
end
MSK.GetRandomLetter = MSK.GetRandomString
exports('GetRandomString', MSK.GetRandomString)

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

MSK.TableContains = function(table, value)
    if not table or not value then return end
    
    if type(value) == 'table' then
        for k, v in pairs(table) do
            for k2, v2 in pairs(value) do
                if v == v2 then
                    return true
                end
            end
        end
    else
        for k, v in pairs(table) do
            if v == value then
                return true
            end
        end
    end
    return false
end
MSK.Table_Contains = MSK.TableContains
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
        if Timeouts[requestId] then Timeouts[requestId] = nil return end
        cb()
    end)

    Timeout = requestId
    return requestId
end
MSK.AddTimeout = MSK.SetTimeout
exports('SetTimeout', MSK.SetTimeout)

MSK.DelTimeout = function(requestId)
    if not requestId then return end
    Timeouts[requestId] = true
end
exports('DelTimeout', MSK.DelTimeout)

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
        script = code
        local action = ...
        local args = {...}
        table.remove(args, 1)

        print(script, Config.LoggingTypes[action], ...)
    else
        print(script, Config.LoggingTypes[code], ...)
    end
end
MSK.logging = MSK.Logging
exports('Logging', MSK.Logging)

exports('getConfig', function()
    return Config
end)

logging = function(code, ...)
    if not Config.Debug then return end
    print(script, Config.LoggingTypes[code], ...)
end