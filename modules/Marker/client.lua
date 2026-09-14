--------------------------------------------------------------------------------
-- MSK.Marker (client)
--
-- A marker with its settings stored once, drawn with a single call per frame.
--
--   local marker = MSK.Marker.New({ type = 1, coords = vec3(...), width = 1.5, height = 0.5 })
--
--   CreateThread(function()
--       while nearby do
--           marker:Draw()
--           Wait(0)
--       end
--   end)
--
-- MSK.Marker.Draw(data) draws a marker for one frame without keeping an object.
-- Marker types: https://docs.fivem.net/docs/game-references/markers/
--------------------------------------------------------------------------------
local Marker = {}

local Instance = {}
Instance.__index = Instance

local ZERO = vector3(0.0, 0.0, 0.0)
local DEFAULT_COLOR = { r = 0, g = 230, b = 118, a = 150 }

local function readColor(color)
    if not color then return DEFAULT_COLOR end

    return {
        r = color.r or color[1] or 255,
        g = color.g or color[2] or 255,
        b = color.b or color[3] or 255,
        a = color.a or color[4] or 150,
    }
end

local function toVector3(value, fallback)
    if value == nil then return fallback end
    if type(value) == 'vector3' then return value end
    return vector3(value.x or value[1] or 0.0, value.y or value[2] or 0.0, value.z or value[3] or 0.0)
end

local function prepare(data)
    assert(type(data) == 'table', 'Parameter "data" has to be a table on function MSK.Marker')
    assert(data.coords, 'Field "coords" is required on function MSK.Marker')

    return {
        type = math.floor(tonumber(data.type) or 1),
        coords = toVector3(data.coords),
        direction = toVector3(data.direction, ZERO),
        rotation = toVector3(data.rotation, ZERO),
        width = tonumber(data.width) or 1.0,
        height = tonumber(data.height) or 1.0,
        color = readColor(data.color),
        bobUpAndDown = data.bobUpAndDown == true,
        faceCamera = data.faceCamera == true,
        rotate = data.rotate == true,
        textureDict = data.textureDict,
        textureName = data.textureName,
    }
end

local function draw(m)
    local c, d, r, col = m.coords, m.direction, m.rotation, m.color

    DrawMarker(m.type,
        c.x, c.y, c.z,
        d.x, d.y, d.z,
        r.x, r.y, r.z,
        m.width, m.width, m.height,
        col.r, col.g, col.b, col.a,
        m.bobUpAndDown, m.faceCamera, 2, m.rotate,
        m.textureDict, m.textureName, false)
end

---@param data { type?: number, coords: vector3, width?: number, height?: number, color?: table, direction?: vector3, rotation?: vector3, bobUpAndDown?: boolean, faceCamera?: boolean, rotate?: boolean, textureDict?: string, textureName?: string }
function Marker.New(data)
    return setmetatable(prepare(data), Instance)
end

---Draws a marker for this frame only.
function Marker.Draw(data)
    draw(prepare(data))
end

---Draws the marker for this frame.
function Instance:Draw()
    draw(self)
end

---@param coords vector3
function Instance:SetCoords(coords)
    self.coords = toVector3(coords)
end

---@param color { r: number, g: number, b: number, a?: number }|number[]
function Instance:SetColor(color)
    self.color = readColor(color)
end

---Distance from the marker to `coords`, by default the player.
---@param coords? vector3
---@return number
function Instance:GetDistance(coords)
    return #(self.coords - (coords and toVector3(coords) or MSK.Player.coords))
end

return Marker
