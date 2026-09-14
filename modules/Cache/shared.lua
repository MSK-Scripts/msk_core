--------------------------------------------------------------------------------
-- MSK.Cache
--
-- Remembers the result of a function under a key, so an expensive lookup runs
-- once instead of on every call.
--
--   local jobs = MSK.Cache('jobs', function() return MSK.GetJobs() end, 60000)
--
--   MSK.Cache.Set('config', data)
--   MSK.Cache.Clear('jobs')        -- the next call runs the function again
--
-- `ttl` is in milliseconds. Without it the value stays until it is cleared. A
-- nil result is not stored, the function runs again on the next call. The cache
-- belongs to the resource that uses it, other resources do not see it.
--------------------------------------------------------------------------------
local Cache = {}

local entries = {}

local function isFresh(entry)
    return entry ~= nil and (entry.expires == nil or entry.expires > GetGameTimer())
end

local function store(key, value, ttl)
    if value == nil then
        entries[key] = nil
        return
    end

    ttl = tonumber(ttl)
    local expires = nil
    if ttl and ttl > 0 then expires = GetGameTimer() + ttl end

    entries[key] = { value = value, expires = expires }
end

---The cached value of `key`. When there is none (or it expired) `fn` runs and
---its result is stored. `fn` may also be a plain value.
---@param key any
---@param fn? function|any
---@param ttl? number milliseconds
---@return any
function Cache.Get(key, fn, ttl)
    assert(key ~= nil, 'Parameter "key" is nil on function MSK.Cache.Get')

    local entry = entries[key]
    if isFresh(entry) then return entry.value end

    if fn == nil then
        entries[key] = nil
        return nil
    end

    local value = fn
    if type(fn) == 'function' then value = fn() end

    store(key, value, ttl)
    return value
end

---Stores `value` under `key`, replacing what was there.
---@param key any
---@param value any
---@param ttl? number milliseconds
function Cache.Set(key, value, ttl)
    assert(key ~= nil, 'Parameter "key" is nil on function MSK.Cache.Set')
    store(key, value, ttl)
end

---@param key any
---@return boolean
function Cache.Has(key)
    local entry = entries[key]
    if isFresh(entry) then return true end

    entries[key] = nil
    return false
end

---Removes `key`, or everything when called without a key.
---@param key? any
function Cache.Clear(key)
    if key == nil then
        entries = {}
    else
        entries[key] = nil
    end
end

return setmetatable(Cache, {
    __call = function(_, key, fn, ttl) return Cache.Get(key, fn, ttl) end
})
