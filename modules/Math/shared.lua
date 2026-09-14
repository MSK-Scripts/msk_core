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

    num = tonumber(num)
    decimal = math.floor(tonumber(decimal) or 0)

    -- Halves round away from zero (2.5 -> 3, -2.5 -> -3). string.format rounded
    -- them to even (2.5 -> 2) and raised an error for negative places, which
    -- now round to tens, hundreds, ...
    -- For negative places divide and multiply by a whole power of ten. Scaling
    -- by 10 ^ -2 = 0.01 is not exact in binary and turned 1200 into
    -- 1200.0000000000002.
    local factor = 10 ^ math.abs(decimal)
    local scaled = decimal >= 0 and num * factor or num / factor
    scaled = scaled >= 0 and math.floor(scaled + 0.5) or math.ceil(scaled - 0.5)

    if decimal <= 0 then
        local result = decimal == 0 and scaled or scaled * math.tointeger(factor)
        return math.tointeger(result) or result
    end

    return scaled / factor
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

---Limits `value` to the range between `min` and `max`.
---@param value number
---@param min number
---@param max number
---@return number
function Math.Clamp(value, min, max)
    assert(type(value) == 'number', 'Parameter "value" has to be a number on function MSK.Math.Clamp')
    assert(type(min) == 'number' and type(max) == 'number', 'Parameters "min" and "max" have to be numbers on function MSK.Math.Clamp')

    if min > max then min, max = max, min end
    if value < min then return min end
    if value > max then return max end
    return value
end

---Linear interpolation: `t` = 0 gives `from`, `t` = 1 gives `to`. Works with
---numbers and vectors alike.
---@generic T : number|vector2|vector3|vector4
---@param from T
---@param to T
---@param t number
---@return T
function Math.Lerp(from, to, t)
    assert(type(t) == 'number', 'Parameter "t" has to be a number on function MSK.Math.Lerp')
    return from + (to - from) * t
end

---Where `value` sits between `from` and `to`, as a factor (0 at `from`, 1 at
---`to`). The opposite of Lerp.
---@param from number
---@param to number
---@param value number
---@return number
function Math.InverseLerp(from, to, value)
    if from == to then return 0.0 end
    return (value - from) / (to - from)
end

---Maps `value` from one range onto another, e.g. 0..100 health onto 0..1000.
---With `clamp` the result stays inside the output range.
---@param value number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@param clamp? boolean
---@return number
function Math.Remap(value, inMin, inMax, outMin, outMax, clamp)
    local t = Math.InverseLerp(inMin, inMax, value)
    if clamp then t = Math.Clamp(t, 0.0, 1.0) end
    return Math.Lerp(outMin, outMax, t)
end

---Converts '#rgb', '#rgba', '#rrggbb' or '#rrggbbaa' (with or without '#') into
---numbers from 0 to 255. Alpha is nil when the input has none.
---@param hex string
---@return integer r, integer g, integer b, integer? a
function Math.HexToRgb(hex)
    assert(type(hex) == 'string', 'Parameter "hex" has to be a string on function MSK.Math.HexToRgb')

    local clean = hex:gsub('^#', '')

    if #clean == 3 or #clean == 4 then
        clean = clean:gsub('.', '%0%0')
    end

    assert((#clean == 6 or #clean == 8) and not clean:find('[^%x]'), ('Invalid hex color "%s" on function MSK.Math.HexToRgb'):format(hex))

    local r = tonumber(clean:sub(1, 2), 16)
    local g = tonumber(clean:sub(3, 4), 16)
    local b = tonumber(clean:sub(5, 6), 16)
    local a = #clean == 8 and tonumber(clean:sub(7, 8), 16) or nil

    return r, g, b, a
end

---Converts color channels from 0 to 255 into '#rrggbb', or '#rrggbbaa' when
---`a` is given. Values outside the range are clamped.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return string
function Math.RgbToHex(r, g, b, a)
    local function channel(value)
        return math.floor(Math.Clamp(tonumber(value) or 0, 0, 255) + 0.5)
    end

    local hex = ('#%02x%02x%02x'):format(channel(r), channel(g), channel(b))

    if a ~= nil then
        hex = hex .. ('%02x'):format(channel(a))
    end

    return hex
end

---Numbers from a vector, a table ({x=, y=, z=, w=} or {1, 2, 3}) or a string
---('1.0, 2, 3' or 'vector3(1.0, 2, 3)').
---@param input any
---@return number ...
function Math.ToScalars(input)
    local inputType = type(input)

    if inputType == 'vector2' then return input.x, input.y end
    if inputType == 'vector3' then return input.x, input.y, input.z end
    if inputType == 'vector4' then return input.x, input.y, input.z, input.w end
    if inputType == 'number' then return input end

    if inputType == 'table' then
        if input.x ~= nil then
            return input.x, input.y, input.z, input.w or input.h or input.heading
        end
        return table.unpack(input)
    end

    if inputType == 'string' then
        local inner = input:gsub('^%s*vec%a*%d?%s*%(', ''):gsub('%)%s*$', '')
        local values = {}

        for part in inner:gmatch('[^,]+') do
            local value = tonumber((part:gsub('^%s+', ''):gsub('%s+$', '')))
            assert(value, ('Invalid number "%s" in "%s" on function MSK.Math.ToScalars'):format(part, input))
            values[#values + 1] = value
        end

        return table.unpack(values)
    end

    error(('Cannot read numbers from a value of type "%s" on function MSK.Math.ToScalars'):format(inputType), 2)
end

---A vector2, vector3 or vector4, depending on how many numbers `input` holds.
---Accepts everything MSK.Math.ToScalars accepts.
---@param input any
---@return vector2|vector3|vector4|number
function Math.ToVector(input)
    local inputType = type(input)
    if inputType == 'vector2' or inputType == 'vector3' or inputType == 'vector4' then
        return input
    end

    local x, y, z, w = Math.ToScalars(input)

    if w ~= nil then return vector4(x, y, z, w) end
    if z ~= nil then return vector3(x, y, z) end
    if y ~= nil then return vector2(x, y) end
    return x
end

---Rotation in degrees that tilts an object's up axis onto a surface normal,
---e.g. the normal a raycast returns. The object is rotated around X (pitch)
---and then around Y (roll); the heading stays 0, set it separately.
---@param normal vector3
---@return vector3
function Math.NormalToRotation(normal)
    assert(normal and normal.x and normal.y and normal.z, 'Parameter "normal" has to be a vector3 on function MSK.Math.NormalToRotation')

    local length = math.sqrt(normal.x ^ 2 + normal.y ^ 2 + normal.z ^ 2)
    if length == 0 then return vector3(0.0, 0.0, 0.0) end

    local nx, ny, nz = normal.x / length, normal.y / length, normal.z / length

    local roll = math.deg(math.asin(Math.Clamp(nx, -1.0, 1.0)))
    local pitch = math.deg(math.atan(-ny, nz))

    return vector3(pitch, roll, 0.0)
end

---A whole number as hex string with 0x prefix, e.g. 255 -> '0xff'.
---@param value number
---@param upper? boolean uppercase digits ('0xFF')
---@return string
function Math.ToHex(value, upper)
    local int = math.tointeger(tonumber(value))
    assert(int, 'Parameter "value" has to be a whole number on function MSK.Math.ToHex')

    return (upper and '0x%X' or '0x%x'):format(int)
end

---A color as vector4(r, g, b, a) with red, green and blue from 0 to 255 and
---alpha from 0 to 1 (default 1). Accepts '#rgb', '#rrggbb', '#rrggbbaa' (the
---'#' may be left out for 6 and 8 digits), 'rgb(255, 0, 0)',
---'rgba(255, 0, 0, 0.5)', '255, 0, 0', { r =, g =, b =, a = }, { 255, 0, 0 }
---and vectors. Values outside the range raise an error.
---@param input string|table|vector3|vector4
---@return vector4
function Math.ToRgba(input)
    local r, g, b, a
    local kind = type(input)

    if kind == 'string' then
        local text = input:gsub('^%s+', ''):gsub('%s+$', '')
        local isHex = text:find('^#') or ((#text == 6 or #text == 8) and not text:find('[^%x]'))

        if isHex then
            r, g, b, a = Math.HexToRgb(text)
            if a then a = a / 255 end
        else
            local inner = text:gsub('^rgba?%s*%(', ''):gsub('%)%s*$', '')
            r, g, b, a = Math.ToScalars(inner)
        end
    elseif kind == 'table' and input.r ~= nil then
        r, g, b, a = input.r, input.g, input.b, input.a
    else
        r, g, b, a = Math.ToScalars(input)
    end

    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    assert(r and g and b, ('Color "%s" needs red, green and blue on function MSK.Math.ToRgba'):format(tostring(input)))

    if a == nil then a = 1.0 end
    a = tonumber(a)

    local inRange = r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255
        and a ~= nil and a >= 0 and a <= 1
    assert(inRange, ('Color "%s" is out of range (rgb 0-255, alpha 0-1) on function MSK.Math.ToRgba'):format(tostring(input)))

    return vector4(r + 0.0, g + 0.0, b + 0.0, a + 0.0)
end

return Math
