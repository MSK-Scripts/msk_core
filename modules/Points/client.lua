local Points = {}
local RegisteredPoints = {}
local closestPoint

-- Own counter instead of #RegisteredPoints + 1. Removing a point leaves a hole
-- in that table, and the length operator is undefined on a table with holes, so
-- a new point could be handed an id that is still in use.
local nextPointId = 0

local function RemovePoint(self)
    if closestPoint and closestPoint.id and closestPoint.id == self.id then
        closestPoint = nil
    end

    if self.onRemove then
        self.onRemove(self)
    end

    RegisteredPoints[self.id] = nil
end

local function ConvertCoords(coords)
    local coordsType = type(coords)

    if coordsType ~= 'vector3' and coordsType ~= 'vec3' then
        if coordsType == 'table' then
            return vector3(coords[1] or coords.x, coords[2] or coords.y, coords[3] or coords.z)
        elseif coordsType == 'vector4' or coordsType == 'vec4' then
            return vector3(coords.x, coords.y, coords.z)
        end

        error(("expected type 'vector3', received type '%s' (value: %s)"):format(coordsType, coords))
    end

    return coords
end

CreateThread(function()
    while true do
        local sleep = 250
        local coords = MSK.Player.coords

        if closestPoint and #(coords - closestPoint.coords) > closestPoint.distance then
            closestPoint = nil
        end

        for _, point in pairs(RegisteredPoints) do
            local distance = #(coords - point.coords)

            if distance <= point.distance then
                point.currentDistance = distance

                if closestPoint then
                    -- currentDistance is cleared when a point is left, and the
                    -- closest point is not always cleared in the same pass, so
                    -- compare against a value that always exists.
                    if distance < (closestPoint.currentDistance or math.huge) then
                        closestPoint.isClosest = nil
                        point.isClosest = true
                        closestPoint = point
                    end
                elseif distance < point.distance then
                    point.isClosest = true
                    closestPoint = point
                end

                if not point.inside then
                    point.inside = true

                    if point.onEnter then
                        point.onEnter(point)
                    end
                end
            elseif point.inside then
                point.inside = false
                point.currentDistance = nil

                if point.onExit then
                    point.onExit(point)
                end
            end
        end

        Wait(sleep)
    end
end)

function Points.Add(properties)
    if type(properties) ~= "table" then
        return
    end

    if not properties.coords or not properties.distance then
        error(("expected type 'table' for parameter 'properties', received type '%s'"):format(type(properties)))
    end

    nextPointId = nextPointId + 1
    local id = nextPointId
    local self = properties

    self.id = id
    self.coords = ConvertCoords(self.coords)

    -- Bound to this point, so both point.Remove() and point:Remove() work. It
    -- used to be the bare function, which needs `self` and only ever got it
    -- through the colon call.
    self.Remove = function()
        return RemovePoint(self)
    end

    RegisteredPoints[id] = self

    return self
end

function Points.Remove(pointId)
    local point = RegisteredPoints[pointId]
    if not point then return false end

    -- Called with a dot and no argument, this reached RemovePoint with self as
    -- nil and died on self.id. Removing a point through MSK.Points.Remove could
    -- not work at all.
    RemovePoint(point)
    return true
end

function Points.GetAllPoints()
    return RegisteredPoints
end

function Points.GetClosestPoint()
    return closestPoint
end

return Points
