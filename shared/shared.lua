local Timeouts, Charset = {}, {}

for i = 48, 57 do table.insert(Charset, string.char(i)) end
for i = 65, 90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

MSK.GetRandomString = function(length)
    assert(length, 'Parameter "length" is nil on function MSK.GetRandomString')
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

MSK.StartsWith = function(str, startStr)
    assert(str and type(str) == 'string', 'Parameter "str" has to be a string on function MSK.StartsWith')
    assert(startStr and type(startStr) == 'string', 'Parameter "startStr" has to be a string on function MSK.StartsWith')
    return str:sub(1, #startStr) == startStr
end
exports('StartsWith', MSK.StartsWith)

MSK.Round = function(num, decimal)
    assert(num and tonumber(num), 'Parameter "num" has to be a number on function MSK.Round')
    assert(not decimal or decimal and tonumber(decimal), 'Parameter "decimal" has to be a number on function MSK.Round')
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end
exports('Round', MSK.Round)

MSK.Trim = function(str, bool)
    assert(str and tostring(str), 'Parameter "str" has to be a string on function MSK.Trim')
    str = tostring(str)
    if bool then return str:gsub("^%s*(.-)%s*$", "%1") end
    return str:gsub("%s+", "")
end
exports('Trim', MSK.Trim)

MSK.Split = function(str, delimiter)
    assert(str and type(str) == 'string', 'Parameter "str" has to be a string on function MSK.Split')
    assert(delimiter and type(delimiter) == 'string', 'Parameter "delimiter" has to be a string on function MSK.Split')
    local result = {}
    
    for match in str:gmatch("([^"..delimiter.."]+)") do
		result[#result + 1] = match
	end

    return result 
end
exports('Split', MSK.Split)

MSK.TableContains = function(tbl, val)
    assert(tbl and type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.TableContains')
    assert(val, 'Parameter "val" is nil on function MSK.TableContains')
    
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
    assert(int and tonumber(int), 'Parameter "int" has to be a number on function MSK.Comma')
    assert(not tag or tag and type(tag) == 'string' and not tonumber(tag), 'Parameter "tag" has to be a string on function MSK.Comma')
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
    assert(ms and tonumber(ms), 'Parameter "ms" has to be a number on function MSK.SetTimeout')
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
    assert(requestId, 'Parameter "requestId" is nil on function MSK.ClearTimeout')
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
    assert(code and type(code) == 'string', 'Parameter "code" has to be a string on function MSK.Logging')
    local script = ('[^2%s^0]'):format(GetInvokingResource() or 'msk_core')
    print(('%s %s'):format(script, Config.LoggingTypes[code] or Config.LoggingTypes['debug']), ...)
end
MSK.logging = MSK.Logging -- Support for old Versions
exports('Logging', MSK.Logging)

logging = function(code, ...)
    if not Config.Debug then return end
    assert(code and type(code) == 'string', 'Parameter "code" has to be a string on function MSK.Logging')
    local script = ('[^2%s^0]'):format(GetCurrentResourceName())
    print(('%s %s'):format(script, Config.LoggingTypes[code]), ...)
end