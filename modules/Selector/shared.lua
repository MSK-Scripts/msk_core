--------------------------------------------------------------------------------
-- MSK.Selector
--
-- Random selection from lists, with or without weights.
--
-- Weighted entries are written as { value, weight } or { value = x, weight = n }:
--
--   MSK.Selector.Weighted({
--       { 'common', 70 },
--       { 'rare', 25 },
--       { 'legendary', 5 },
--   })
--
-- MSK.Selector.New() returns a pool of named sets for scripts that draw from
-- the same lists again and again (loot tables, spawn points, ...).
--------------------------------------------------------------------------------
local Selector = {}

local function entryValue(entry)
    if type(entry) == 'table' then
        if entry.value ~= nil then return entry.value end
        return entry[1]
    end
    return entry
end

local function entryWeight(entry)
    local weight = type(entry) == 'table' and (entry.weight or entry[2]) or nil
    weight = tonumber(weight)
    return weight and weight > 0 and weight or 0
end

local function copy(list)
    local result = {}
    for i = 1, #list do result[i] = list[i] end
    return result
end

---A random element of the list, plus its index.
---@param list any[]
---@return any, integer?
function Selector.Pick(list)
    assert(type(list) == 'table', 'Parameter "list" has to be a table on function MSK.Selector.Pick')
    if #list == 0 then return nil end

    local index = math.random(1, #list)
    return list[index], index
end

---`amount` random elements. With `unique` (default true) no element is taken
---twice, so the result is at most as long as the list.
---@param list any[]
---@param amount integer
---@param unique? boolean
---@return any[]
function Selector.PickMany(list, amount, unique)
    assert(type(list) == 'table', 'Parameter "list" has to be a table on function MSK.Selector.PickMany')
    assert(type(amount) == 'number' and amount >= 0, 'Parameter "amount" has to be a number >= 0 on function MSK.Selector.PickMany')

    local result = {}

    if unique == false then
        for i = 1, amount do
            result[i] = list[math.random(1, #list)]
        end
        return result
    end

    local pool = copy(list)
    for i = 1, math.min(amount, #pool) do
        local index = math.random(1, #pool)
        result[i] = pool[index]
        pool[index] = pool[#pool]
        pool[#pool] = nil
    end
    return result
end

---A random value where each entry's chance is its share of the total weight.
---Entries with a weight of 0 or less are never picked.
---@param entries table[]
---@return any, integer?
function Selector.Weighted(entries)
    assert(type(entries) == 'table', 'Parameter "entries" has to be a table on function MSK.Selector.Weighted')

    local total = 0
    for i = 1, #entries do
        total = total + entryWeight(entries[i])
    end
    if total <= 0 then return nil end

    local roll = math.random() * total
    for i = 1, #entries do
        local weight = entryWeight(entries[i])
        if weight > 0 then
            roll = roll - weight
            if roll <= 0 then
                return entryValue(entries[i]), i
            end
        end
    end

    -- Floating point rounding can leave a sliver after the last entry.
    for i = #entries, 1, -1 do
        if entryWeight(entries[i]) > 0 then
            return entryValue(entries[i]), i
        end
    end
end

---`amount` weighted picks. With `unique` (default true) an entry leaves the
---pool once it was picked.
---@param entries table[]
---@param amount integer
---@param unique? boolean
---@return any[]
function Selector.WeightedMany(entries, amount, unique)
    assert(type(entries) == 'table', 'Parameter "entries" has to be a table on function MSK.Selector.WeightedMany')
    assert(type(amount) == 'number' and amount >= 0, 'Parameter "amount" has to be a number >= 0 on function MSK.Selector.WeightedMany')

    local result = {}
    local pool = unique == false and entries or copy(entries)

    for i = 1, amount do
        local value, index = Selector.Weighted(pool)
        if index == nil then break end

        result[i] = value

        if unique ~= false then
            table.remove(pool, index)
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- Pools
--------------------------------------------------------------------------------
local Pool = {}
Pool.__index = Pool

---Adds or replaces the set `name`.
---@param name string
---@param entries any[]
function Pool:Add(name, entries)
    assert(type(name) == 'string', 'Parameter "name" has to be a string on function Selector:Add')
    assert(type(entries) == 'table', 'Parameter "entries" has to be a table on function Selector:Add')
    self.sets[name] = entries
    return entries
end

---@param name string
---@return boolean removed
function Pool:Remove(name)
    local existed = self.sets[name] ~= nil
    self.sets[name] = nil
    return existed
end

---@param name string
---@return any[]?
function Pool:Get(name)
    return self.sets[name]
end

---Names of all sets in this pool.
---@return string[]
function Pool:Names()
    local names = {}
    for name in pairs(self.sets) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

local function requireSet(self, name)
    local set = self.sets[name]
    assert(set, ('Selector set "%s" does not exist'):format(tostring(name)))
    return set
end

function Pool:Pick(name) return Selector.Pick(requireSet(self, name)) end
function Pool:PickMany(name, amount, unique) return Selector.PickMany(requireSet(self, name), amount, unique) end
function Pool:Weighted(name) return Selector.Weighted(requireSet(self, name)) end
function Pool:WeightedMany(name, amount, unique) return Selector.WeightedMany(requireSet(self, name), amount, unique) end

---Creates a pool of named sets, optionally prefilled with { [name] = entries }.
---@param sets? table<string, any[]>
function Selector.New(sets)
    local pool = setmetatable({ sets = {} }, Pool)

    if sets then
        for name, entries in pairs(sets) do
            pool:Add(name, entries)
        end
    end

    return pool
end

return Selector
