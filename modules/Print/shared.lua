--------------------------------------------------------------------------------
-- MSK.Print
--
-- Console output with levels that can be switched per resource at runtime,
-- without touching code:
--
--   setr msk:printlevel "warn"               -- every resource
--   setr msk:printlevel:my_script "debug"    -- one resource, wins over the above
--
-- Levels, from quiet to loud: error, warn, info (default), verbose, debug.
-- A message is printed when its level is at or below the configured one.
--
-- `setr` replicates the convar to clients, so the same line controls both sides.
--------------------------------------------------------------------------------
local Print = {}

local RESOURCE = GetCurrentResourceName()

local LEVELS = { error = 1, warn = 2, info = 3, verbose = 4, debug = 5 }

local LABELS = {
    error = '^1[ERROR]^7',
    warn = '^3[WARN]^7',
    info = '^4[INFO]^7',
    verbose = '^5[VERBOSE]^7',
    debug = '^6[DEBUG]^7',
}

-- Reading the convar on every call would be wasted work inside hot loops, so
-- the level is cached and refreshed at most once per REFRESH milliseconds.
local REFRESH = 2000
local cachedLevel, cachedAt = nil, -REFRESH
local override = nil

local function currentLevel()
    if override then return override end

    local now = GetGameTimer()
    if not cachedLevel or now - cachedAt >= REFRESH then
        local value = GetConvar('msk:printlevel:' .. RESOURCE, '')
        if value == '' then
            value = GetConvar('msk:printlevel', 'info')
        end

        cachedLevel = LEVELS[value:lower()] or LEVELS.info
        cachedAt = now
    end

    return cachedLevel
end

local function stringify(value)
    local valueType = type(value)

    if valueType == 'table' then
        local ok, encoded = pcall(json.encode, value, { indent = true })
        return ok and encoded or tostring(value)
    end

    return tostring(value)
end

local function output(level, ...)
    if LEVELS[level] > currentLevel() then return end

    local count = select('#', ...)
    local parts = {}

    for i = 1, count do
        parts[i] = stringify((select(i, ...)))
    end

    print(('[^2%s^7] %s %s^7'):format(RESOURCE, LABELS[level], table.concat(parts, '\t')))
end

function Print.Error(...) output('error', ...) end
function Print.Warn(...) output('warn', ...) end
function Print.Info(...) output('info', ...) end
function Print.Verbose(...) output('verbose', ...) end
function Print.Debug(...) output('debug', ...) end

---Overrides the level for this resource until the next restart. nil goes back
---to the convars.
---@param level? 'error'|'warn'|'info'|'verbose'|'debug'
function Print.SetLevel(level)
    if level == nil then
        override = nil
        return
    end

    local value = LEVELS[level]
    assert(value, ('Unknown print level "%s" on function MSK.Print.SetLevel'):format(tostring(level)))
    override = value
end

---The name of the level that is currently active for this resource.
---@return string
function Print.GetLevel()
    local current = currentLevel()
    for name, value in pairs(LEVELS) do
        if value == current then return name end
    end
end

---True when a message of `level` would be printed. Useful to skip building an
---expensive debug string that nobody would see.
---@param level 'error'|'warn'|'info'|'verbose'|'debug'
---@return boolean
function Print.IsEnabled(level)
    local value = LEVELS[level]
    return value ~= nil and value <= currentLevel()
end

return setmetatable(Print, {
    __call = function(_, ...) output('info', ...) end
})
