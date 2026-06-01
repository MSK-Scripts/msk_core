local Math = {}

-- Digits '0'..'9'
local Numbers = {}
for i = 48, 57 do Numbers[#Numbers + 1] = string.char(i) end
math.randomseed(GetGameTimer())

---Generates a random digit string of length `length`.
---@param length number
---@return string
function Math.Random(length)
    assert(length, 'Parameter "length" is nil on function MSK.Math.Random')
    return length > 0 and Math.Random(length - 1) .. Numbers[math.random(1, #Numbers)] or ''
end
Math.Number = Math.Random -- Backwards compatibility (MSK.Math.Number)

---Rounds `num` to `decimal` decimal places (default 0).
---@param num number
---@param decimal? number
---@return number
function Math.Round(num, decimal)
    assert(num and tonumber(num), 'Parameter "num" has to be a number on function MSK.Math.Round')
    assert(not decimal or decimal and tonumber(decimal), 'Parameter "decimal" has to be a number on function MSK.Math.Round')
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end

---Inserts a thousands separator (`tag`, default '.') into an integer.
---@param int number
---@param tag? string
---@return string
function Math.Comma(int, tag)
    assert(int and tonumber(int), 'Parameter "int" has to be a number on function MSK.Math.Comma')
    assert(not tag or tag and type(tag) == 'string' and not tonumber(tag), 'Parameter "tag" has to be a string on function MSK.Math.Comma')
    if not tag then tag = '.' end

    local newInt = int
    local replaced
    while true do
        newInt, replaced = string.gsub(newInt, "^(-?%d+)(%d%d%d)", '%1' .. tag .. '%2')
        if replaced == 0 then break end
    end

    return newInt
end

return Math
