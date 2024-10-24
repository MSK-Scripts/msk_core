local Points = {}
local RegisteredPoints = {}
local closestPoint

local RemovePoint = function(self)
    if closestPoint and closestPoint.id and closestPoint.id == self.id then
        closestPoint = nil
    end

    if self.onRemove then
        self.onRemove(self)
    end

    RegisteredPoints[self.id] = nil
end

local ConvertCoords = function(coords)
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

        for k, point in pairs(RegisteredPoints) do
            local distance = #(coords - point.coords)

            if distance <= point.distance then
                point.currentDistance = distance

                if closestPoint then
                    if distance < closestPoint.currentDistance then
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

Points.Add = function(properties)
    if type(properties) ~= "table" then
        return
    end

    if not properties.coords or not properties.distance then
        error(("expected type 'table' for parameter 'properties', received type '%s'"):format(type(properties)))
    end

    local id = #RegisteredPoints + 1
    local self = properties

    self.id = id
    self.coords = ConvertCoords(self.coords)
    self.Remove = RemovePoint

    RegisteredPoints[id] = self

    return self
end
exports('AddPoint', Points.Add)

Points.Remove = function(pointId)
    if not RegisteredPoints[pointId] then return false end
    RegisteredPoints[pointId].Remove()
    return true
end
exports('RemovePoint', Points.Remove)

Points.GetAllPoints = function()
    return RegisteredPoints
end
exports('GetAllPoints', Points.GetAllPoints)

Points.GetClosestPoint = function()
    return closestPoint
end
exports('GetClosestPoint', Points.GetClosestPoint)

MSK.Points = Points