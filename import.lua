local CORE = 'msk_core'
local consumer = GetCurrentResourceName()

-- Lua 5.4 is mandatory (load(), integer division, goto semantics etc.)
if not _VERSION:find('5.4') then
    error("msk_core requires Lua 5.4 — please set \"lua54 'yes'\" in the fxmanifest.", 2)
end

-- Guard: never run import.lua inside msk_core itself.
if consumer == CORE then return end

-- Guard: catch double inclusion within the same consumer.
if MSK and MSK.name == CORE then
    error(("msk_core was imported multiple times in '%s' — remove the duplicate '@msk_core/import.lua' entry in the fxmanifest.")
        :format(consumer))
end

-- msk_core must be running before a consumer may import it.
if GetResourceState(CORE) ~= 'started' then
    error("^1msk_core is not started — it must start BEFORE this resource.^0", 0)
end

local core = exports[CORE]

-- Obtain the bootstrap acknowledgement: true when ready, otherwise an error text.
-- pcall in case msk_core is 'started' but its 'hasLoaded' export is not (yet)
-- reachable or crashed while loading itself -> understandable message.
local probed, ready = pcall(function() return core:hasLoaded() end)
if not probed then
    error(("^1msk_core is started, but its 'hasLoaded' export does not respond — likely a load error inside msk_core itself.^0\n%s"):format(ready), 0)
end
if ready ~= true then error(ready, 2) end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local side = IsDuplicityVersion() and 'server' or 'client'
local readFile = LoadResourceFile

-- Sentinel for modules that return nothing. Prevents repeated load attempts
-- and makes the cache hit (rawget ~= nil) unambiguous.
local EMPTY = function() end

-- Load the backwards-compat aliases once (bundled in compat/aliases.lua,
-- deliberately NOT scattered inline across the modules).
local alias = {}
do
    local src = readFile(CORE, 'compat/aliases.lua')
    if src then
        local build, lerr = load(src, '@@msk_core/compat/aliases.lua')
        if not build then
            print(("[^3msk_core^0] ^3Warning:^0 compat/aliases.lua failed to compile — aliases are ignored.\n%s"):format(lerr))
        else
            local ok, result = pcall(build)
            if ok and type(result) == 'table' then
                alias = result
            else
                print(("[^3msk_core^0] ^3Warning:^0 compat/aliases.lua did not return a valid table — aliases are ignored.%s")
                    :format(ok and '' or ('\n' .. tostring(result))))
            end
        end
    end
end

-- Reads modules/<name>/shared.lua + modules/<name>/<side>.lua and compiles
-- them together. Returns: compiled function OR nil (no module present).
local function compile(name)
    local base   = 'modules/' .. name
    local common = readFile(CORE, base .. '/shared.lua')
    local sided  = readFile(CORE, base .. '/' .. side .. '.lua')

    local src = sided
    if common then
        src = src and (common .. '\n' .. sided) or common
    end
    if not src then return nil end

    local chunk, err = load(src, '@@msk_core/' .. base .. '/' .. side .. '.lua')
    if not chunk then
        error(("^1msk_core: module '%s' failed to compile — %s^0"):format(name, err), 3)
    end
    return chunk
end

-- Executes a module into the consumer runtime and caches it under store[name].
-- Returns: module value (possibly EMPTY) OR nil if the module does not exist.
local function mount(store, name)
    local chunk = compile(name)
    if not chunk then return nil end

    local ok, value = pcall(chunk)
    if not ok then
        error(("^1msk_core: runtime error while executing module '%s' — %s^0"):format(name, value), 3)
    end

    store[name] = value == nil and EMPTY or value
    return store[name]
end

-- Metatable resolver (__index/__call): see the order in the header above.
local function resolve(store, name)
    local cached = rawget(store, name)
    if cached ~= nil then return cached end

    local mod = mount(store, name)
    if mod ~= nil then return mod end

    local a = alias[name]
    if a then
        local target = mount(store, a.module)
        if target == nil then
            error(("^1msk_core: alias '%s' points to module '%s', which does not exist.^0"):format(name, tostring(a.module)), 2)
        end

        local value = target
        if a.key ~= nil then
            value = target[a.key]
            if value == nil then
                error(("^1msk_core: alias '%s' points to '%s.%s' — not present there.^0"):format(name, tostring(a.module), tostring(a.key)), 2)
            end
        end

        store[name] = value
        return value
    end

    -- No module, no alias -> export proxy onto a function running inside msk_core.
    local proxy = function(...) return core[name](nil, ...) end
    store[name] = proxy
    return proxy
end

--------------------------------------------------------------------------------
-- Global handle MSK (fresh, consumer-local table -> MSK.name is correct)
--------------------------------------------------------------------------------
MSK = setmetatable({
    name = consumer,
    context = side,
}, {
    __index = resolve,
    __call  = function(t, name) return resolve(t, name) end,
})
_ENV.MSK = MSK

--------------------------------------------------------------------------------
-- Optional eager loading: the consumer may request modules up front in its
-- own fxmanifest, e.g.:
--     msk_core 'callback'
--     msk_core 'player'
--------------------------------------------------------------------------------
local eager = GetNumResourceMetadata(consumer, 'msk_core')
for i = 0, eager - 1 do
    local name = GetResourceMetadata(consumer, 'msk_core', i)
    if name and rawget(MSK, name) == nil then
        if mount(MSK, name) == nil then
            print(("[^3msk_core^0] ^3Warning:^0 eager import '%s' (from @%s/fxmanifest.lua) — no such module exists."):format(name, consumer))
        end
    end
end
