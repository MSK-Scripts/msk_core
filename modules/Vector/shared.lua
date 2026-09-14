local Vector = {}

local function getTableHeading(coords)
    return coords.h or coords.w or coords.heading or 0.0
end

---Converts a coordinate (table/vector3/vector4) into a vector* string.
---@param coords table|vector3|vector4
---@return string
function Vector.CoordsToString(coords)
    assert(coords, 'Parameter "coords" has to be a vector on function MSK.CoordsToString')
    local typ = type(coords)

    if typ == 'table' then
        if coords.h or coords.w then
            return string.format("vector4(%s, %s, %s, %s)", coords.x, coords.y, coords.z, getTableHeading(coords))
        end
        return string.format("vector3(%s, %s, %s)", coords.x, coords.y, coords.z)
    elseif typ == 'vector3' then
        return string.format("vector3(%s, %s, %s)", coords.x, coords.y, coords.z)
    elseif typ == 'vector4' then
        return string.format("vector4(%s, %s, %s, %s)", coords.x, coords.y, coords.z, coords.w)
    end

    return coords
end

---Reduces a vector4 to vector3; otherwise unchanged.
---@param vec any
---@return any
function Vector.VectorToVector(vec)
    local typ = type(vec)

    if typ == 'vec4' or typ == 'vector4' then
        return vector3(vec.x, vec.y, vec.z)
    end

    return vec
end

---Converts a table coordinate into vector3 or vector4.
---@param coords table
---@param toType 'vector3'|'vector4'
---@return vector3|vector4|nil
function Vector.TableToVector(coords, toType)
    assert(coords and type(coords) == 'table', 'Parameter "tbl" has to be a table on function MSK.TableToVector')

    if toType == 'vector3' then
        return vector3(coords.x, coords.y, coords.z)
    elseif toType == 'vector4' then
        return vector4(coords.x, coords.y, coords.z, getTableHeading(coords))
    end
end

---World position of an offset relative to a position and heading, e.g. a spot
---two metres in front of a vehicle. The offset is (right, forward, up).
---`rotation` is a heading in degrees, or a vector3 rotation whose z is used.
---  MSK.Vector.GetRelativeCoords(GetEntityCoords(veh), GetEntityHeading(veh), vector3(0.0, 2.0, 0.0))
---@param coords vector3|vector4|table
---@param rotation number|vector3
---@param offset vector3|table
---@return vector3
function Vector.GetRelativeCoords(coords, rotation, offset)
    assert(coords and coords.x, 'Parameter "coords" has to be a vector on function MSK.Vector.GetRelativeCoords')
    assert(offset and offset.x, 'Parameter "offset" has to be a vector on function MSK.Vector.GetRelativeCoords')

    local heading = type(rotation) == 'number' and rotation or (rotation and rotation.z) or 0.0
    local rad = math.rad(heading)
    local cos, sin = math.cos(rad), math.sin(rad)

    local x = offset.x * cos - offset.y * sin
    local y = offset.x * sin + offset.y * cos

    return vector3(coords.x + x, coords.y + y, coords.z + (offset.z or 0.0))
end

return Vector
