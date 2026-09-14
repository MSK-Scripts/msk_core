local Points = {}
local RegisteredPoints = {}
local closestPoint

-- Own counter instead of #RegisteredPoints + 1. Removing a point leaves a hole
-- in that table, and the length operator is undefined on a table with holes, so
-- a new point could be handed an id that is still in use.
local nextPointId = 0

-- Callbacks run protected. An error in one onEnter/onExit used to end the
-- thread below, and with it every point of the resource.
local function runCallback(point, name)
    local fn = point[name]
    if not fn then return end

    local ok, err = pcall(fn, point)

    -- Logged once per point and callback, nearby runs every frame.
    if not ok then
        point.failedCallbacks = point.failedCallbacks or {}

        if not point.failedCallbacks[name] then
            point.failedCallbacks[name] = true
            MSK.Logging('error', ('Point %s: %s failed: %s'):format(point.id, name, err))
        end
    end
end

local function RemovePoint(self)
    if closestPoint and closestPoint.id and closestPoint.id == self.id then
        closestPoint = nil
    end

    -- Leaving by removal counts as leaving, like with zones. A TextUI opened
    -- in onEnter stayed on screen when the point was removed while inside.
    if self.inside then
        self.inside = false
        self.currentDistance = nil
        runCallback(self, 'onExit')
    end

    runCallback(self, 'onRemove')

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

-- Every 250 ms all points are measured. Points with a `nearby` callback want it
-- every frame while the player is inside, so between two full passes only
-- those are measured again and their callback runs each frame.
CreateThread(function()
    while true do
        local coords = MSK.Player.coords
        local nearbyPoints = {}

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
                    runCallback(point, 'onEnter')
                end

                if point.nearby and point.inside then
                    nearbyPoints[#nearbyPoints + 1] = point
                end
            elseif point.inside then
                point.inside = false
                point.currentDistance = nil
                runCallback(point, 'onExit')
            end
        end

        if #nearbyPoints == 0 then
            Wait(250)
        else
            local nextPass = GetGameTimer() + 250

            repeat
                local frameCoords = MSK.Player.coords

                for i = 1, #nearbyPoints do
                    local point = nearbyPoints[i]

                    -- Removed or left by a callback in the meantime.
                    if point.inside and RegisteredPoints[point.id] == point then
                        point.currentDistance = #(frameCoords - point.coords)
                        runCallback(point, 'nearby')
                    end
                end

                Wait(0)
            until GetGameTimer() >= nextPass
        end
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

    -- Set when the point comes in through the AddPoint export, so it can be
    -- dropped when that resource stops. Its callbacks point into it.
    self.owner = GetInvokingResource()

    -- Bound to this point, so both point.Remove() and point:Remove() work. It
    -- used to be the bare function, which needs `self` and only ever got it
    -- through the colon call.
    self.Remove = function()
        return RemovePoint(self)
    end

    RegisteredPoints[id] = self

    return self
end

-- Points of a stopped resource are dropped without calling their callbacks,
-- those would call into a resource that is gone.
AddEventHandler('onResourceStop', function(resource)
    for id, point in pairs(RegisteredPoints) do
        if point.owner == resource then
            if closestPoint == point then closestPoint = nil end
            RegisteredPoints[id] = nil
        end
    end
end)

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

---All points the player is inside of, closest first.
---@return table[]
function Points.GetNearbyPoints()
    local list = {}

    for _, point in pairs(RegisteredPoints) do
        if point.inside then
            list[#list + 1] = point
        end
    end

    table.sort(list, function(a, b)
        return (a.currentDistance or math.huge) < (b.currentDistance or math.huge)
    end)

    return list
end

return Points
