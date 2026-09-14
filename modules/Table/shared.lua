local Table = {}

---Checks whether `val` is contained in `tbl` (recursive if `val` is itself a table).
---@param tbl table
---@param val any
---@return boolean
function Table.Contains(tbl, val)
    assert(tbl and type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Contains')
    -- nil only. `assert(val)` also refused false, and a list containing false
    -- failed as soon as the recursion below reached that element.
    assert(val ~= nil, 'Parameter "val" is nil on function MSK.Table.Contains')

    if type(val) == 'table' then
        for _, value in pairs(tbl) do
            if Table.Contains(val, value) then
                return true
            end
        end
        return false
    else
        for _, v in pairs(tbl) do
            if v == val then
                return true
            end
        end
    end

    return false
end

---JSON dump (indented) of a table.
---@param tbl any
---@return string
function Table.Dump(tbl)
    return type(tbl) == "table" and json.encode(tbl, { indent = true }) or tostring(tbl)
end

---Lua-source-like, recursive string dump.
---@param tbl any
---@param n? number
---@return string
function Table.DumpString(tbl, n)
    if not n then n = 0 end
    if type(tbl) ~= "table" then return tostring(tbl) end

    local s = '{\n'
    for k, v in pairs(tbl) do
        if type(k) ~= 'number' then k = '"' .. k .. '"' end
        for _ = 1, n, 1 do s = s .. "    " end
        s = s .. '    [' .. k .. '] = ' .. Table.DumpString(v, n + 1) .. ',\n'
    end

    for _ = 1, n, 1 do s = s .. "    " end

    return s .. '}'
end

---Number of entries (including non-sequential).
---@param tbl table
---@return number
function Table.Size(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

---First index of `val` in the sequence `tbl`, otherwise -1.
---@param tbl table
---@param val any
---@return number
function Table.Index(tbl, val)
    for i = 1, #tbl, 1 do
        if tbl[i] == val then
            return i
        end
    end
    return -1
end

-- Last index of `val` in the sequence `tbl`, otherwise -1.
---@param tbl table
---@param val any
---@return number
function Table.LastIndex(tbl, val)
    for i = #tbl, 1, -1 do
        if tbl[i] == val then
            return i
        end
    end
    return -1
end

---First index + value of `val`, otherwise (nil, val).
---@param tbl table
---@param val any
---@return number|nil, any
function Table.Find(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            return i, val
        end
    end
    return nil, val
end

---Reverses the order of a sequence.
---@param tbl table
---@return table
function Table.Reverse(tbl)
    local newTbl = {}
    for i = #tbl, 1, -1 do
        newTbl[#newTbl + 1] = tbl[i]
    end
    return newTbl
end

---Deep copy including metatable.
---@param tbl table
---@return table
function Table.Clone(tbl)
    assert(tbl and type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Clone')

    local clone = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            clone[k] = Table.Clone(v)
        else
            clone[k] = v
        end
    end

    return setmetatable(clone, getmetatable(tbl))
end

-- Credit: https://stackoverflow.com/a/15706820
---Sorted iterator over `tbl`. `order(tbl, a, b)` optional for custom sorting.
---@param tbl table
---@param order? fun(tbl: table, a: any, b: any): boolean
---@return fun(): any, any
function Table.Sort(tbl, order)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end

    if order then
        table.sort(keys, function(a, b)
            return order(tbl, a, b)
        end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], tbl[keys[i]]
        end
    end
end

-- getmetatable() on a frozen table returns this marker instead of the real
-- metatable, which also stops anyone from swapping the metatable out.
local FROZEN = 'msk_core:frozen'
local frozenChildren = setmetatable({}, { __mode = 'k' })

---Read-only view of `tbl`. Writing to it raises an error; reading, pairs, ipairs
---and # behave as usual. With `deep`, nested tables come back frozen as well.
---The original table stays writable, the view reflects changes made to it.
---@param tbl table
---@param deep? boolean
---@return table
function Table.Freeze(tbl, deep)
    assert(type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Freeze')

    if getmetatable(tbl) == FROZEN then return tbl end

    local children = deep and {} or nil
    local proxy = {}

    local function read(key)
        local value = tbl[key]

        if deep and type(value) == 'table' then
            local child = children[value]
            if not child then
                child = Table.Freeze(value, true)
                children[value] = child
            end
            return child
        end

        return value
    end

    setmetatable(proxy, {
        __index = function(_, key) return read(key) end,
        __newindex = function(_, key)
            error(('attempt to modify a frozen table (key "%s")'):format(tostring(key)), 2)
        end,
        __len = function() return #tbl end,
        __pairs = function()
            return function(_, key)
                local nextKey = next(tbl, key)
                if nextKey ~= nil then
                    return nextKey, read(nextKey)
                end
            end, proxy, nil
        end,
        __metatable = FROZEN,
    })

    if children then frozenChildren[proxy] = children end

    return proxy
end

---True when `tbl` is a view returned by MSK.Table.Freeze.
---@param tbl any
---@return boolean
function Table.IsFrozen(tbl)
    return type(tbl) == 'table' and getmetatable(tbl) == FROZEN
end

---New table with the entries of `base`, overwritten by those of `override`.
---With `deep`, nested tables present on both sides are merged too instead of
---being replaced. Neither input is changed.
---@param base table
---@param override table
---@param deep? boolean
---@return table
function Table.Merge(base, override, deep)
    assert(type(base) == 'table', 'Parameter "base" has to be a table on function MSK.Table.Merge')
    assert(type(override) == 'table', 'Parameter "override" has to be a table on function MSK.Table.Merge')

    local result = {}
    for key, value in pairs(base) do
        result[key] = value
    end

    for key, value in pairs(override) do
        if deep and type(value) == 'table' and type(result[key]) == 'table' then
            result[key] = Table.Merge(result[key], value, true)
        else
            result[key] = value
        end
    end

    return result
end

---Deep equality: same keys, and every value equal (nested tables compared by
---content, not by identity).
---@param a any
---@param b any
---@return boolean
function Table.Matches(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end

    for key, value in pairs(a) do
        if not Table.Matches(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

---List of all keys.
---@param tbl table
---@return any[]
function Table.Keys(tbl)
    assert(type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Keys')

    local keys = {}
    for key in pairs(tbl) do
        keys[#keys + 1] = key
    end
    return keys
end

---List of all values.
---@param tbl table
---@return any[]
function Table.Values(tbl)
    assert(type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Values')

    local values = {}
    for _, value in pairs(tbl) do
        values[#values + 1] = value
    end
    return values
end

---Removes every entry from `tbl` in place and returns it. Unlike assigning a
---new table, every reference to it sees the empty table.
---@param tbl table
---@return table
function Table.Wipe(tbl)
    assert(type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Wipe')

    for key in pairs(tbl) do
        tbl[key] = nil
    end
    return tbl
end

return Table
