--------------------------------------------------------------------------------
-- MSK.Grid
--
-- A spatial hash over the X/Y plane. Entries are sorted into square cells, so
-- "what is near this position" only has to look at a handful of entries
-- instead of all of them. MSK.Zones uses it to keep large zone counts cheap.
--
-- An entry is any table with either
--   coords (vector) + radius (number)   or
--   min (vector)    + max (vector)      as an axis-aligned bounding box.
--
--   local grid = MSK.Grid.New(250.0)
--   grid:Add(entry)
--   for _, nearby in ipairs(grid:GetNearby(coords)) do ... end
--------------------------------------------------------------------------------
local Grid = {}
Grid.__index = Grid

local floor = math.floor

local function bounds(entry)
    if entry.min and entry.max then
        return entry.min.x, entry.min.y, entry.max.x, entry.max.y
    end

    local coords = entry.coords
    assert(coords, 'A grid entry needs coords + radius or min + max')

    local radius = entry.radius or 0.0
    return coords.x - radius, coords.y - radius, coords.x + radius, coords.y + radius
end

local function cellKey(cx, cy)
    return cx .. ':' .. cy
end

---Creates a grid with cells of `cellSize` units (default 250).
---@param cellSize? number
function Grid.New(cellSize)
    assert(cellSize == nil or (type(cellSize) == 'number' and cellSize > 0), 'Parameter "cellSize" has to be a number > 0 on function MSK.Grid.New')

    return setmetatable({
        cellSize = cellSize or 250.0,
        cells = {},
        entries = {},
    }, Grid)
end

---Adds an entry, or re-sorts it when it is already in the grid.
---@param entry table
---@return table entry
function Grid:Add(entry)
    if self.entries[entry] then
        self:Remove(entry)
    end

    local minX, minY, maxX, maxY = bounds(entry)
    local size = self.cellSize
    local keys = {}

    for cx = floor(minX / size), floor(maxX / size) do
        for cy = floor(minY / size), floor(maxY / size) do
            local key = cellKey(cx, cy)
            local cell = self.cells[key]

            if not cell then
                cell = {}
                self.cells[key] = cell
            end

            cell[entry] = true
            keys[#keys + 1] = key
        end
    end

    self.entries[entry] = keys
    return entry
end

---@param entry table
---@return boolean removed
function Grid:Remove(entry)
    local keys = self.entries[entry]
    if not keys then return false end

    for i = 1, #keys do
        local cell = self.cells[keys[i]]

        if cell then
            cell[entry] = nil

            if next(cell) == nil then
                self.cells[keys[i]] = nil
            end
        end
    end

    self.entries[entry] = nil
    return true
end

---Entries sharing the cell that contains `coords`.
---@param coords vector3|vector2|table
---@return table[]
function Grid:GetNearby(coords)
    local size = self.cellSize
    local cell = self.cells[cellKey(floor(coords.x / size), floor(coords.y / size))]
    local result, n = {}, 0

    if cell then
        for entry in pairs(cell) do
            n = n + 1
            result[n] = entry
        end
    end

    return result
end

---Entries in any cell touched by the square around `coords` with `radius`.
---No entry appears twice.
---@param coords vector3|vector2|table
---@param radius number
---@return table[]
function Grid:GetInRange(coords, radius)
    local size = self.cellSize
    local seen, result, n = {}, {}, 0

    for cx = floor((coords.x - radius) / size), floor((coords.x + radius) / size) do
        for cy = floor((coords.y - radius) / size), floor((coords.y + radius) / size) do
            local cell = self.cells[cellKey(cx, cy)]

            if cell then
                for entry in pairs(cell) do
                    if not seen[entry] then
                        seen[entry] = true
                        n = n + 1
                        result[n] = entry
                    end
                end
            end
        end
    end

    return result
end

---@return boolean
function Grid:Has(entry)
    return self.entries[entry] ~= nil
end

function Grid:Clear()
    self.cells = {}
    self.entries = {}
end

return { New = Grid.New }
