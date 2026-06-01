local Table = {}

---Checks whether `val` is contained in `tbl` (recursive if `val` is itself a table).
---@param tbl table
---@param val any
---@return boolean
function Table.Contains(tbl, val)
    assert(tbl and type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Contains')
    assert(val, 'Parameter "val" is nil on function MSK.Table.Contains')

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

return Table
