--------------------------------------------------------------------------------
-- Input dialog schema (shared)
--
-- Normalises the rows of MSK.Input.Dialog and validates the values that come
-- back. Both sides use the same rules: the client before it resolves, the
-- server once more on what the client reported, because a client can send
-- anything.
--
-- Field types and what they return:
--   input, textarea   string
--   number, slider    number
--   checkbox          boolean
--   select            the value of the chosen option
--   multi-select      list of option values
--   color             '#rrggbb' (or '#rrggbbaa')
--   date              'YYYY-MM-DD'
--   date-range        { 'YYYY-MM-DD', 'YYYY-MM-DD' }
--   time              'HH:MM'
-- Empty optional fields return nil.
--------------------------------------------------------------------------------
local InputDialog = {}

local function isBlank(value)
    return value == nil or (type(value) == 'string' and value:match('^%s*$') ~= nil)
end

local function isDate(value)
    if type(value) ~= 'string' or not value:match('^%d%d%d%d%-%d%d%-%d%d$') then return false end

    local month, day = tonumber(value:sub(6, 7)), tonumber(value:sub(9, 10))
    return month >= 1 and month <= 12 and day >= 1 and day <= 31
end

local function checkRange(row, number)
    local min, max = tonumber(row.min), tonumber(row.max)
    if min and number < min then return ('must be at least %s'):format(min) end
    if max and number > max then return ('must be at most %s'):format(max) end
end

local function findOption(row, raw)
    for i = 1, #row.options do
        if row.options[i].value == raw then
            return row.options[i].value
        end
    end
end

-- Each validator returns (value) or (nil, error). A blank optional field
-- returns nothing; the required check happens afterwards.
local VALIDATORS = {}

VALIDATORS.input = function(row, raw)
    if isBlank(raw) then return nil end
    if type(raw) ~= 'string' then return nil, 'expected text' end

    local maxLength = tonumber(row.maxLength)
    if maxLength and #raw > maxLength then
        return nil, ('longer than %s characters'):format(maxLength)
    end

    return raw
end

VALIDATORS.textarea = VALIDATORS.input

VALIDATORS.number = function(row, raw)
    if isBlank(raw) then return nil end

    local number = tonumber(raw)
    if not number then return nil, 'expected a number' end

    local rangeError = checkRange(row, number)
    if rangeError then return nil, rangeError end

    return number
end

VALIDATORS.slider = function(row, raw)
    local number = tonumber(raw)
    if not number then return nil, 'expected a number' end

    local rangeError = checkRange({ min = row.min or 0, max = row.max or 100 }, number)
    if rangeError then return nil, rangeError end

    return number
end

VALIDATORS.checkbox = function(row, raw)
    return raw == true
end

VALIDATORS.select = function(row, raw)
    if isBlank(raw) then return nil end

    local value = findOption(row, raw)
    if value == nil then return nil, 'not one of the options' end

    return value
end

VALIDATORS['multi-select'] = function(row, raw)
    if raw == nil then return nil end
    if type(raw) ~= 'table' then return nil, 'expected a list' end
    if #raw == 0 then return nil end

    local result, seen = {}, {}

    for i = 1, #raw do
        local value = findOption(row, raw[i])
        if value == nil then return nil, 'contains a value that is not an option' end

        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end

    return result
end

VALIDATORS.color = function(row, raw)
    if isBlank(raw) then return nil end

    if type(raw) ~= 'string' or not (raw:match('^#%x%x%x%x%x%x$') or raw:match('^#%x%x%x%x%x%x%x%x$')) then
        return nil, 'expected a color like #00e676'
    end

    return raw:lower()
end

VALIDATORS.date = function(row, raw)
    if isBlank(raw) then return nil end
    if not isDate(raw) then return nil, 'expected a date like 2026-09-13' end

    -- ISO dates compare correctly as strings.
    if row.min and raw < row.min then return nil, ('must not be before %s'):format(row.min) end
    if row.max and raw > row.max then return nil, ('must not be after %s'):format(row.max) end

    return raw
end

VALIDATORS['date-range'] = function(row, raw)
    if raw == nil then return nil end
    if type(raw) ~= 'table' then return nil, 'expected two dates' end

    local from, to = raw[1], raw[2]
    if isBlank(from) and isBlank(to) then return nil end

    local fromValue, fromError = VALIDATORS.date(row, from)
    if not fromValue then return nil, fromError or 'start date missing' end

    local toValue, toError = VALIDATORS.date(row, to)
    if not toValue then return nil, toError or 'end date missing' end

    if fromValue > toValue then return nil, 'start date is after the end date' end

    return { fromValue, toValue }
end

VALIDATORS.time = function(row, raw)
    if isBlank(raw) then return nil end

    -- Type check first and match separately: `x and raw:match(...)` would cut
    -- the two captures down to one and leave minutes nil.
    local hours, minutes
    if type(raw) == 'string' then
        hours, minutes = raw:match('^(%d%d):(%d%d)$')
    end

    if not hours or tonumber(hours) > 23 or tonumber(minutes) > 59 then
        return nil, 'expected a time like 20:30'
    end

    return raw
end

---Checks the rows and turns them into plain, serialisable tables. A string
---row is shorthand for a text input with that label.
---@param rows table
---@return table[]
function InputDialog.NormalizeRows(rows)
    assert(type(rows) == 'table' and #rows > 0, 'Parameter "rows" has to be a non-empty list on function MSK.Input.Dialog')

    local result = {}

    for i = 1, #rows do
        local row = rows[i]
        if type(row) == 'string' then row = { label = row } end

        assert(type(row) == 'table', ('Row %d of MSK.Input.Dialog has to be a table or a string'):format(i))

        local rowType = row.type or 'input'
        assert(VALIDATORS[rowType], ('Unknown input type "%s" in row %d of MSK.Input.Dialog'):format(tostring(rowType), i))

        local options
        if row.options then
            options = {}

            for j = 1, #row.options do
                local option = row.options[j]
                if type(option) ~= 'table' then
                    option = { value = option }
                end

                options[j] = { value = option.value, label = option.label or tostring(option.value) }
            end
        end

        if rowType == 'select' or rowType == 'multi-select' then
            assert(options and #options > 0, ('Row %d of MSK.Input.Dialog (%s) needs options'):format(i, rowType))
        end

        result[i] = {
            index = i,
            id = row.id,
            type = rowType,
            label = row.label,
            description = row.description,
            placeholder = row.placeholder,
            icon = row.icon,
            required = row.required == true,
            disabled = row.disabled == true,
            default = row.default,
            min = row.min,
            max = row.max,
            step = row.step,
            maxLength = row.maxLength,
            password = row.password == true,
            options = options,
        }
    end

    return result
end

---Validates the values reported for normalised rows. Returns the cleaned
---values, indexed by row number and additionally by row id where one is set,
---or nil plus the reason.
---@param rows table[] normalised rows
---@param values table values keyed by row number (number or string keys)
---@return table?, string?
function InputDialog.Validate(rows, values)
    if type(values) ~= 'table' then return nil, 'no values received' end

    local result = {}

    for i = 1, #rows do
        local row = rows[i]
        local value, err

        if row.disabled then
            -- A disabled field cannot be changed, whatever the client says.
            value = row.default
        else
            local raw = values[i]
            if raw == nil then raw = values[tostring(i)] end

            value, err = VALIDATORS[row.type](row, raw)
        end

        local name = row.label or row.id or row.type

        if err then
            return nil, ('field %d (%s): %s'):format(i, name, err)
        end

        if row.required and (value == nil or (row.type == 'checkbox' and value ~= true)) then
            return nil, ('field %d (%s) is required'):format(i, name)
        end

        result[i] = value

        if row.id ~= nil then
            result[row.id] = value
        end
    end

    return result
end
