--------------------------------------------------------------------------------
-- MSK.Array
--
-- Functional helpers for sequences (tables with keys 1..n). Every function
-- takes a plain table and returns a plain table, nothing is wrapped in a
-- metatable, so the results also survive an export boundary.
--
-- Callbacks receive (value, index). None of the functions change the input.
--------------------------------------------------------------------------------
local Array = {}

local function assertList(list, fnName)
    assert(type(list) == 'table', ('Parameter "list" has to be a table on function MSK.Array.%s'):format(fnName))
end

local function assertFn(fn, fnName)
    assert(type(fn) == 'function', ('Parameter "fn" has to be a function on function MSK.Array.%s'):format(fnName))
end

---New list with `fn(value, index)` applied to every element.
---@param list any[]
---@param fn fun(value: any, index: integer): any
---@return any[]
function Array.Map(list, fn)
    assertList(list, 'Map')
    assertFn(fn, 'Map')

    local result = {}
    for i = 1, #list do
        result[i] = fn(list[i], i)
    end
    return result
end

---New list with every element for which `fn` returns a truthy value.
---@param list any[]
---@param fn fun(value: any, index: integer): boolean
---@return any[]
function Array.Filter(list, fn)
    assertList(list, 'Filter')
    assertFn(fn, 'Filter')

    local result, n = {}, 0
    for i = 1, #list do
        local value = list[i]
        if fn(value, i) then
            n = n + 1
            result[n] = value
        end
    end
    return result
end

---Folds the list into one value. Without `initial` the first element is the
---starting value and the fold begins at the second one.
---@param list any[]
---@param fn fun(accumulator: any, value: any, index: integer): any
---@param initial? any
---@return any
function Array.Reduce(list, fn, initial)
    assertList(list, 'Reduce')
    assertFn(fn, 'Reduce')

    local accumulator, start = initial, 1
    if accumulator == nil then
        accumulator, start = list[1], 2
    end

    for i = start, #list do
        accumulator = fn(accumulator, list[i], i)
    end
    return accumulator
end

---First element for which `fn` is truthy, plus its index.
---@param list any[]
---@param fn fun(value: any, index: integer): boolean
---@return any, integer?
function Array.Find(list, fn)
    assertList(list, 'Find')
    assertFn(fn, 'Find')

    for i = 1, #list do
        if fn(list[i], i) then
            return list[i], i
        end
    end
end

---Index of the first element for which `fn` is truthy, otherwise nil.
---@param list any[]
---@param fn fun(value: any, index: integer): boolean
---@return integer?
function Array.FindIndex(list, fn)
    local _, index = Array.Find(list, fn)
    return index
end

---True when `fn` is truthy for at least one element.
---@param list any[]
---@param fn fun(value: any, index: integer): boolean
---@return boolean
function Array.Some(list, fn)
    return Array.FindIndex(list, fn) ~= nil
end

---True when `fn` is truthy for every element (and for an empty list).
---@param list any[]
---@param fn fun(value: any, index: integer): boolean
---@return boolean
function Array.Every(list, fn)
    assertList(list, 'Every')
    assertFn(fn, 'Every')

    for i = 1, #list do
        if not fn(list[i], i) then
            return false
        end
    end
    return true
end

---Calls `fn` for every element. Returning false from `fn` stops the loop.
---@param list any[]
---@param fn fun(value: any, index: integer): boolean?
function Array.ForEach(list, fn)
    assertList(list, 'ForEach')
    assertFn(fn, 'ForEach')

    for i = 1, #list do
        if fn(list[i], i) == false then
            return
        end
    end
end

---True when `value` is an element of the list (plain equality).
---@param list any[]
---@param value any
---@return boolean
function Array.Includes(list, value)
    assertList(list, 'Includes')

    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

---Joins any number of lists into a new one.
---@param ... any[]
---@return any[]
function Array.Concat(...)
    local result, n = {}, 0

    for i = 1, select('#', ...) do
        local list = select(i, ...)
        assertList(list, 'Concat')

        for j = 1, #list do
            n = n + 1
            result[n] = list[j]
        end
    end
    return result
end

---Part of the list from `from` to `to` (both inclusive). Negative numbers count
---from the end, -1 is the last element.
---@param list any[]
---@param from? integer
---@param to? integer
---@return any[]
function Array.Slice(list, from, to)
    assertList(list, 'Slice')

    local length = #list
    from = from or 1
    to = to or length

    if from < 0 then from = length + from + 1 end
    if to < 0 then to = length + to + 1 end
    if from < 1 then from = 1 end
    if to > length then to = length end

    local result, n = {}, 0
    for i = from, to do
        n = n + 1
        result[n] = list[i]
    end
    return result
end

---List without duplicates, keeping the first occurrence. `keyFn` decides what
---counts as the same element, by default the value itself.
---@param list any[]
---@param keyFn? fun(value: any): any
---@return any[]
function Array.Unique(list, keyFn)
    assertList(list, 'Unique')

    local seen, result, n = {}, {}, 0
    for i = 1, #list do
        local value = list[i]
        local key = keyFn and keyFn(value) or value

        if key ~= nil and not seen[key] then
            seen[key] = true
            n = n + 1
            result[n] = value
        end
    end
    return result
end

---Flattens nested lists `depth` levels deep (default 1, math.huge for all).
---@param list any[]
---@param depth? number
---@return any[]
function Array.Flatten(list, depth)
    assertList(list, 'Flatten')
    depth = depth or 1

    local result, n = {}, 0

    local function walk(current, level)
        for i = 1, #current do
            local value = current[i]

            if type(value) == 'table' and level < depth and value[1] ~= nil then
                walk(value, level + 1)
            else
                n = n + 1
                result[n] = value
            end
        end
    end

    walk(list, 0)
    return result
end

---Groups the elements by the key `fn` returns: { [key] = { elements } }.
---@param list any[]
---@param fn fun(value: any, index: integer): any
---@return table<any, any[]>
function Array.GroupBy(list, fn)
    assertList(list, 'GroupBy')
    assertFn(fn, 'GroupBy')

    local groups = {}
    for i = 1, #list do
        local value = list[i]
        local key = fn(value, i)

        if key ~= nil then
            local group = groups[key]
            if not group then
                group = {}
                groups[key] = group
            end
            group[#group + 1] = value
        end
    end
    return groups
end

---New list in random order (Fisher-Yates).
---@param list any[]
---@return any[]
function Array.Shuffle(list)
    assertList(list, 'Shuffle')

    local result = {}
    for i = 1, #list do
        result[i] = list[i]
    end

    for i = #result, 2, -1 do
        local j = math.random(1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

---Splits the list into lists of `size` elements. The last one may be shorter.
---@param list any[]
---@param size integer
---@return any[][]
function Array.Chunk(list, size)
    assertList(list, 'Chunk')
    assert(type(size) == 'number' and size >= 1, 'Parameter "size" has to be a number >= 1 on function MSK.Array.Chunk')

    local result, chunk = {}, nil
    for i = 1, #list do
        if (i - 1) % size == 0 then
            chunk = {}
            result[#result + 1] = chunk
        end
        chunk[#chunk + 1] = list[i]
    end
    return result
end

---List of numbers from `from` to `to` in steps of `step` (default 1).
---@param from number
---@param to number
---@param step? number
---@return number[]
function Array.Range(from, to, step)
    assert(type(from) == 'number' and type(to) == 'number', 'Parameters "from" and "to" have to be numbers on function MSK.Array.Range')
    step = step or (from <= to and 1 or -1)
    assert(step ~= 0, 'Parameter "step" must not be 0 on function MSK.Array.Range')

    local result, n = {}, 0
    for value = from, to, step do
        n = n + 1
        result[n] = value
    end
    return result
end

return Array
