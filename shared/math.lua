MSK.Math = {}
local Numbers = {}

for i = 48, 57 do table.insert(Numbers, string.char(i)) end

MSK.Math.Random = function(length)
    assert(length, 'Parameter "length" is nil on function MSK.Math.Random')
    math.randomseed(GetGameTimer())

	return length > 0 and MSK.Math.Random(length - 1) .. Numbers[math.random(1, #Numbers)] or ''
end
MSK.Math.Number = MSK.Math.Random -- Backwards compatibility
MSK.GetRandomNumber = MSK.Math.Random -- Backwards compatibility
exports('GetRandomNumber', MSK.Math.Random)

MSK.Math.Round = function(num, decimal)
    assert(num and tonumber(num), 'Parameter "num" has to be a number on function MSK.Math.Round')
    assert(not decimal or decimal and tonumber(decimal), 'Parameter "decimal" has to be a number on function MSK.Math.Round')
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end
MSK.Round = MSK.Math.Round -- Backwards compatibility
exports('Round', MSK.Math.Round)

MSK.Math.Comma = function(int, tag)
    assert(int and tonumber(int), 'Parameter "int" has to be a number on function MSK.Math.Comma')
    assert(not tag or tag and type(tag) == 'string' and not tonumber(tag), 'Parameter "tag" has to be a string on function MSK.Math.Comma')
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
MSK.Comma = MSK.Math.Comma -- Backwards compatibility
exports('Comma', MSK.Math.Comma)