local getTableHeading = function(coords)
    return coords.h or coords.w or coords.heading or 0.0
end

MSK.CoordsToString = function(coords)
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
exports('CoordsToString', MSK.CoordsToString)

MSK.VectorToVector = function(vec)
    local typ = type(vec)

    if typ == 'vec4' or typ == 'vector4' then
        return vector3(vec.x, vec.y, vec.z)
    end

    return vec
end
exports('VectorToVector', MSK.VectorToVector)

MSK.TableToVector = function(coords, toType)
    assert(coords and type(coords) == 'table', 'Parameter "tbl" has to be a table on function MSK.TableToVector')

    if toType == 'vector3' then
        return vector3(coords.x, coords.y, coords.z)
    elseif toType == 'vector4' then
        return vector4(coords.x, coords.y, coords.z, getTableHeading(coords))
    end
end
exports('TableToVector', MSK.TableToVector)