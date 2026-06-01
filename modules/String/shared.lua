local String = {}

-- Letters 'A'..'Z' and 'a'..'z'
local Charset = {}
for i = 65, 90 do Charset[#Charset + 1] = string.char(i) end
for i = 97, 122 do Charset[#Charset + 1] = string.char(i) end
math.randomseed(GetGameTimer())

---Generates a random letter string of length `length`.
---@param length number
---@return string
function String.Random(length)
    assert(length, 'Parameter "length" is nil on function MSK.String.Random')
    return length > 0 and String.Random(length - 1) .. Charset[math.random(1, #Charset)] or ''
end

---Checks whether `str` begins with `startStr`.
---@param str string
---@param startStr string
---@return boolean
function String.StartsWith(str, startStr)
    assert(str and type(str) == 'string', 'Parameter "str" has to be a string on function MSK.String.StartsWith')
    assert(startStr and type(startStr) == 'string', 'Parameter "startStr" has to be a string on function MSK.String.StartsWith')
    return str:sub(1, #startStr) == startStr
end

---Trims `str`. Without `bool`: only leading/trailing whitespace; with `bool`: ALL whitespace.
---@param str string
---@param bool? boolean
---@return string
function String.Trim(str, bool)
    assert(str and tostring(str), 'Parameter "str" has to be a string on function MSK.String.Trim')
    str = tostring(str)
    -- Fix BUG-003: parentheses -> only the string, the gsub counter is not leaked. See Bugfixes.md.
    if bool then return (str:gsub("%s+", "")) end
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

-- Legacy: the top-level MSK.Trim from v2 has an INVERTED bool semantic
-- compared to String.Trim (and to the 'Trim' export)
---@param str string
---@param bool? boolean
---@return string
function String.TrimLegacy(str, bool)
    if bool then return String.Trim(str) end
    return String.Trim(str, true)
end

---Splits `str` at every `delimiter` character into a list.
---@param str string
---@param delimiter string
---@return string[]
function String.Split(str, delimiter)
    assert(str and type(str) == 'string', 'Parameter "str" has to be a string on function MSK.String.Split')
    assert(delimiter and type(delimiter) == 'string', 'Parameter "delimiter" has to be a string on function MSK.String.Split')

    local result = {}
    for match in str:gmatch("([^" .. delimiter .. "]+)") do
        result[#result + 1] = match
    end

    return result
end

return String
