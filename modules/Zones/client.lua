--------------------------------------------------------------------------------
-- MSK.Zones (client)
--
-- Areas that react when the player walks in or out. Three shapes:
--
--   MSK.Zones.Sphere({ coords = vec3(...), radius = 5.0, ... })
--   MSK.Zones.Box({ coords = vec3(...), size = vec3(4.0, 6.0, 3.0), rotation = 90.0, ... })
--   MSK.Zones.Poly({ points = { vec3(...), vec3(...), vec3(...) }, thickness = 4.0, ... })
--
-- Every shape takes these optional fields:
--   onEnter = function(zone) end   once, when the player enters
--   onExit  = function(zone) end   once, when the player leaves
--   inside  = function(zone) end   every frame while the player is inside
--   debug   = true                 draws the zone
--
-- The table you pass in becomes the zone, so any field of your own stays on it.
-- zone:Remove() deletes it; when the player is inside at that moment, onExit
-- still runs, so a TextUI opened in onEnter does not get stuck.
--
-- Zones live in the resource that created them and are checked four times a
-- second against the grid cell the player is in, so the cost does not grow
-- with the total number of zones on the map.
--------------------------------------------------------------------------------
local Zones = {}

local CHECK_INTERVAL = 250

local grid = MSK.Grid.New(250.0)
local zones = {}
local nextId = 0

local insideZones = {}     -- [zone] = true
local frameLoopRunning = false
local debugLoopRunning = false

local Zone = {}
Zone.__index = Zone

local function toVector3(value, name)
    local valueType = type(value)

    if valueType == 'vector3' then return value end
    if valueType == 'vector4' or valueType == 'table' then
        return vector3(value.x or value[1], value.y or value[2], value.z or value[3] or 0.0)
    end

    error(('Parameter "%s" has to be a vector3, received %s'):format(name, valueType), 3)
end

local function safeCall(zone, fnName)
    local fn = zone[fnName]
    if not fn then return end

    local ok, err = pcall(fn, zone)
    if not ok then
        print(('[^1ERROR^0] MSK.Zones: %s of zone %s failed: %s'):format(fnName, zone.name or zone.id, err))
    end
end

--------------------------------------------------------------------------------
-- Containment
--------------------------------------------------------------------------------
local function sphereContains(zone, coords)
    return #(coords - zone.coords) <= zone.radius
end

local function boxContains(zone, coords)
    local dx, dy = coords.x - zone.coords.x, coords.y - zone.coords.y

    -- Rotate the point into the box's own frame (inverse of the box heading).
    local localX = dx * zone.cos + dy * zone.sin
    local localY = -dx * zone.sin + dy * zone.cos
    local localZ = coords.z - zone.coords.z

    return math.abs(localX) <= zone.size.x / 2
        and math.abs(localY) <= zone.size.y / 2
        and math.abs(localZ) <= zone.size.z / 2
end

local function pointInPolygon(x, y, points)
    local inside = false
    local j = #points

    for i = 1, #points do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y

        if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
            inside = not inside
        end

        j = i
    end

    return inside
end

local function polyContains(zone, coords)
    return coords.z >= zone.minZ and coords.z <= zone.maxZ
        and pointInPolygon(coords.x, coords.y, zone.points)
end

---True when `coords` lies inside the zone.
---@param coords vector3
---@return boolean
function Zone:Contains(coords)
    return self.containsFn(self, toVector3(coords, 'coords'))
end

---True while the player is inside the zone.
---@return boolean
function Zone:IsInside()
    return insideZones[self] == true
end

---@param state boolean
function Zone:SetDebug(state)
    self.debug = state and true or false
    if self.debug then Zones._startDebugLoop() end
end

---Deletes the zone. Runs onExit first when the player is inside.
function Zone:Remove()
    if not zones[self.id] then return end

    if insideZones[self] then
        insideZones[self] = nil
        safeCall(self, 'onExit')
    end

    grid:Remove(self)
    zones[self.id] = nil

    if self.onRemove then safeCall(self, 'onRemove') end
end

--------------------------------------------------------------------------------
-- Loops
--------------------------------------------------------------------------------
local function startFrameLoop()
    if frameLoopRunning then return end
    frameLoopRunning = true

    CreateThread(function()
        while true do
            local any = false

            for zone in pairs(insideZones) do
                if zone.inside then
                    any = true
                    safeCall(zone, 'inside')
                end
            end

            if not any then break end
            Wait(0)
        end

        frameLoopRunning = false
    end)
end

CreateThread(function()
    while true do
        local coords = MSK.Player.coords

        if coords then
            local candidates = grid:GetNearby(coords)
            local nowInside = {}

            for i = 1, #candidates do
                local zone = candidates[i]
                if zone.containsFn(zone, coords) then
                    nowInside[zone] = true
                end
            end

            for zone in pairs(insideZones) do
                if not nowInside[zone] then
                    insideZones[zone] = nil
                    safeCall(zone, 'onExit')
                end
            end

            local needsFrameLoop = false

            for zone in pairs(nowInside) do
                if not insideZones[zone] then
                    insideZones[zone] = true
                    safeCall(zone, 'onEnter')
                end

                if zone.inside then needsFrameLoop = true end
            end

            if needsFrameLoop then startFrameLoop() end
        end

        Wait(CHECK_INTERVAL)
    end
end)

--------------------------------------------------------------------------------
-- Debug drawing
--------------------------------------------------------------------------------
local function drawQuad(a, b, c, d, r, g, bl, alpha)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, r, g, bl, alpha)
    DrawPoly(c.x, c.y, c.z, b.x, b.y, b.z, a.x, a.y, a.z, r, g, bl, alpha)
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, r, g, bl, alpha)
    DrawPoly(d.x, d.y, d.z, c.x, c.y, c.z, a.x, a.y, a.z, r, g, bl, alpha)
end

local function drawWalls(corners, bottom, top, color)
    local count = #corners

    for i = 1, count do
        local current = corners[i]
        local following = corners[i % count + 1]

        local a = vector3(current.x, current.y, bottom)
        local b = vector3(following.x, following.y, bottom)
        local c = vector3(following.x, following.y, top)
        local d = vector3(current.x, current.y, top)

        drawQuad(a, b, c, d, color[1], color[2], color[3], color[4])
        DrawLine(a.x, a.y, a.z, d.x, d.y, d.z, color[1], color[2], color[3], 255)
        DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, color[1], color[2], color[3], 255)
        DrawLine(d.x, d.y, d.z, c.x, c.y, c.z, color[1], color[2], color[3], 255)
    end
end

local function drawZone(zone)
    local color = insideZones[zone] and { 0, 230, 118, 60 } or { 244, 63, 94, 45 }

    if zone.shape == 'sphere' then
        local diameter = zone.radius * 2.0
        DrawMarker(28, zone.coords.x, zone.coords.y, zone.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            diameter, diameter, diameter, color[1], color[2], color[3], color[4], false, false, 2, false, nil, nil, false)
    elseif zone.shape == 'box' then
        drawWalls(zone.corners, zone.coords.z - zone.size.z / 2, zone.coords.z + zone.size.z / 2, color)
    else
        drawWalls(zone.points, zone.minZ, zone.maxZ, color)
    end
end

function Zones._startDebugLoop()
    if debugLoopRunning then return end
    debugLoopRunning = true

    CreateThread(function()
        while true do
            local any = false

            for _, zone in pairs(zones) do
                if zone.debug then
                    any = true
                    drawZone(zone)
                end
            end

            if not any then break end
            Wait(0)
        end

        debugLoopRunning = false
    end)
end

--------------------------------------------------------------------------------
-- Creation
--------------------------------------------------------------------------------
local function register(zone)
    nextId = nextId + 1
    zone.id = nextId

    setmetatable(zone, Zone)
    zones[zone.id] = zone
    grid:Add(zone)

    if zone.debug then Zones._startDebugLoop() end

    return zone
end

---@param data { coords: vector3, radius: number, onEnter?: function, onExit?: function, inside?: function, debug?: boolean }
function Zones.Sphere(data)
    assert(type(data) == 'table', 'Parameter "data" has to be a table on function MSK.Zones.Sphere')
    assert(type(data.radius) == 'number' and data.radius > 0, 'Field "radius" has to be a number > 0 on function MSK.Zones.Sphere')

    data.shape = 'sphere'
    data.coords = toVector3(data.coords, 'coords')
    data.containsFn = sphereContains

    return register(data)
end

---@param data { coords: vector3, size: vector3, rotation?: number, onEnter?: function, onExit?: function, inside?: function, debug?: boolean }
function Zones.Box(data)
    assert(type(data) == 'table', 'Parameter "data" has to be a table on function MSK.Zones.Box')

    data.shape = 'box'
    data.coords = toVector3(data.coords, 'coords')
    data.size = toVector3(data.size or vector3(2.0, 2.0, 2.0), 'size')
    data.rotation = tonumber(data.rotation) or 0.0

    local rad = math.rad(data.rotation)
    data.cos, data.sin = math.cos(rad), math.sin(rad)

    local hx, hy = data.size.x / 2, data.size.y / 2
    local corners = {}

    for i, sign in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
        local lx, ly = sign[1] * hx, sign[2] * hy
        corners[i] = vector3(
            data.coords.x + lx * data.cos - ly * data.sin,
            data.coords.y + lx * data.sin + ly * data.cos,
            data.coords.z
        )
    end

    data.corners = corners
    data.radius = math.sqrt(hx * hx + hy * hy)
    data.containsFn = boxContains

    return register(data)
end

---@param data { points: vector3[], thickness?: number, minZ?: number, maxZ?: number, onEnter?: function, onExit?: function, inside?: function, debug?: boolean }
function Zones.Poly(data)
    assert(type(data) == 'table', 'Parameter "data" has to be a table on function MSK.Zones.Poly')
    assert(type(data.points) == 'table' and #data.points >= 3, 'Field "points" needs at least 3 points on function MSK.Zones.Poly')

    data.shape = 'poly'

    local points = {}
    local sumZ = 0.0
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

    for i = 1, #data.points do
        local point = toVector3(data.points[i], 'points[' .. i .. ']')
        points[i] = point
        sumZ = sumZ + point.z

        if point.x < minX then minX = point.x end
        if point.y < minY then minY = point.y end
        if point.x > maxX then maxX = point.x end
        if point.y > maxY then maxY = point.y end
    end

    local thickness = tonumber(data.thickness) or 4.0
    local centerZ = sumZ / #points

    data.points = points
    data.minZ = tonumber(data.minZ) or (centerZ - thickness / 2)
    data.maxZ = tonumber(data.maxZ) or (centerZ + thickness / 2)
    data.min = vector3(minX, minY, data.minZ)
    data.max = vector3(maxX, maxY, data.maxZ)
    data.coords = vector3((minX + maxX) / 2, (minY + maxY) / 2, centerZ)
    data.containsFn = polyContains

    return register(data)
end

---All zones of this resource, keyed by id.
---@return table<number, table>
function Zones.GetAll()
    return zones
end

---The zones the player is inside right now.
---@return table[]
function Zones.GetInside()
    local result = {}
    for zone in pairs(insideZones) do
        result[#result + 1] = zone
    end
    return result
end

---@param id number
---@return boolean removed
function Zones.Remove(id)
    local zone = zones[id]
    if not zone then return false end

    zone:Remove()
    return true
end

return Zones
