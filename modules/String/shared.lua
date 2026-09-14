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

    assert(delimiter ~= '', 'Parameter "delimiter" must not be empty on function MSK.String.Split')

    -- Plain search for the whole delimiter. It used to be pasted into a
    -- character class: '%' or ']' broke the pattern, and '::' split on every
    -- single ':'. Empty pieces are left out, as before.
    local result = {}
    local start = 1

    while true do
        local from, to = str:find(delimiter, start, true)
        local piece = str:sub(start, from and from - 1 or #str)

        if piece ~= '' then
            result[#result + 1] = piece
        end

        if not from then break end
        start = to + 1
    end

    return result
end

local Digits = {}
for i = 48, 57 do Digits[#Digits + 1] = string.char(i) end

local Upper, Lower = {}, {}
for i = 65, 90 do Upper[#Upper + 1] = string.char(i) end
for i = 97, 122 do Lower[#Lower + 1] = string.char(i) end

local Alphanumeric = {}
for _, set in ipairs({ Digits, Upper, Lower }) do
    for i = 1, #set do Alphanumeric[#Alphanumeric + 1] = set[i] end
end

local PatternSets = {
    ['1'] = Digits,
    ['A'] = Upper,
    ['a'] = Lower,
    ['.'] = Alphanumeric,
}

---Random string following a pattern, e.g. for plates or phone numbers:
---  1 = digit, A = uppercase letter, a = lowercase letter, . = letter or digit
---Every other character is kept as it is. `^` keeps the next character literal,
---so '^1' produces a real 1.
---  MSK.String.RandomPattern('11AAA111')   -- '42KQZ907'
---With `length` the result has exactly that many characters: a shorter pattern
---is repeated, a longer result is cut.
---  MSK.String.RandomPattern('1', 6)        -- '804215'
---@param pattern string
---@param length? number
---@return string
local function fillPattern(pattern)
    local result = {}
    local escaped = false

    for i = 1, #pattern do
        local char = pattern:sub(i, i)

        if escaped then
            result[#result + 1] = char
            escaped = false
        elseif char == '^' then
            escaped = true
        else
            local set = PatternSets[char]
            result[#result + 1] = set and set[math.random(1, #set)] or char
        end
    end

    return table.concat(result)
end

function String.RandomPattern(pattern, length)
    assert(pattern and type(pattern) == 'string', 'Parameter "pattern" has to be a string on function MSK.String.RandomPattern')

    if length == nil then
        return fillPattern(pattern)
    end

    length = math.tointeger(tonumber(length))
    assert(length and length >= 0, 'Parameter "length" has to be a whole number of 0 or more on function MSK.String.RandomPattern')

    local parts, size = {}, 0

    while size < length do
        local piece = fillPattern(pattern)

        -- A pattern that produces nothing (empty, or only '^') cannot fill it.
        if piece == '' then break end

        parts[#parts + 1] = piece
        size = size + #piece
    end

    return table.concat(parts):sub(1, length)
end

return String
