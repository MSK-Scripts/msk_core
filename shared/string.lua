MSK.String = {}
local Charset = {}

for i = 65, 90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

MSK.String.Random = function(length)
    assert(length, 'Parameter "length" is nil on function MSK.String.Random')
    math.randomseed(GetGameTimer())

	return length > 0 and MSK.String.Random(length - 1) .. Charset[math.random(1, #Charset)] or ''
end
MSK.GetRandomString = MSK.String.Random -- Backwards compatibility
exports('GetRandomString', MSK.String.Random)

MSK.String.StartsWith = function(str, startStr)
    assert(str and type(str) == 'string', 'Parameter "str" has to be a string on function MSK.String.StartsWith')
    assert(startStr and type(startStr) == 'string', 'Parameter "startStr" has to be a string on function MSK.String.StartsWith')
    return str:sub(1, #startStr) == startStr
end
MSK.StartsWith = MSK.String.StartsWith -- Backwards compatibility
exports('StartsWith', MSK.String.StartsWith)

MSK.String.Trim = function(str, bool)
    assert(str and tostring(str), 'Parameter "str" has to be a string on function MSK.String.Trim')
    str = tostring(str)
    if bool then return str:gsub("%s+", "") end
    return str:gsub("^%s*(.-)%s*$", "%1")
end
exports('Trim', MSK.String.Trim)

-- Backwards compatibility
MSK.Trim = function(str, bool)
    if bool then return MSK.String.Trim(str) end
    return MSK.String.Trim(str, true)
end

MSK.String.Split = function(str, delimiter)
    assert(str and type(str) == 'string', 'Parameter "str" has to be a string on function MSK.String.Split')
    assert(delimiter and type(delimiter) == 'string', 'Parameter "delimiter" has to be a string on function MSK.String.Split')
    local result = {}
    
    for match in str:gmatch("([^"..delimiter.."]+)") do
		result[#result + 1] = match
	end

    return result 
end
MSK.Split = MSK.String.Split -- Backwards compatibility
exports('Split', MSK.String.Split)