MSK = MSK or {}

local resourceName = GetCurrentResourceName()
MSK.name = resourceName
MSK.context = IsDuplicityVersion() and 'server' or 'client'

-- Config binding (the Config global comes from config.lua, loaded before this).
MSK.Config = Config

MSK.GetConfig = function()
    return MSK.Config
end
exports('Config', MSK.GetConfig)
exports('GetConfig', MSK.GetConfig)

--------------------------------------------------------------------------------
-- Lazy-in-core module loader
-- Loads a module into the msk_core runtime (NOT into the consumer) — only on
-- demand — and caches the result. Mirror of the consumer loader in import.lua,
-- here for core-internal use (export registry, bridge, features).
--------------------------------------------------------------------------------
local readFile = LoadResourceFile
local side = MSK.context
local coreCache = {}

local function mountCore(name)
    local cached = coreCache[name]
    if cached ~= nil then return cached end

    local base   = 'modules/' .. name
    local common = readFile(resourceName, base .. '/shared.lua')
    local sided  = readFile(resourceName, base .. '/' .. side .. '.lua')

    local src = sided
    if common then
        src = src and (common .. '\n' .. sided) or common
    end
    if not src then
        coreCache[name] = false
        return false
    end

    local chunk, err = load(src, '@@msk_core/' .. base .. '/' .. side .. '.lua')
    if not chunk then
        error(("^1msk_core: in-core import of module '%s' failed — %s^0"):format(name, err), 2)
    end

    local ok, value = pcall(chunk)
    if not ok then
        error(("^1msk_core: runtime error in in-core module '%s' — %s^0"):format(name, value), 2)
    end

    coreCache[name] = value == nil and false or value
    return coreCache[name]
end
MSK.LoadModule = mountCore

--------------------------------------------------------------------------------
-- Core-MSK lazy __index: resolves PURE module namespaces (Math, String, Table,
-- Vector, Timeout, Request, …) on demand in the msk_core runtime, so that core
-- code can reference itself across modules (e.g. Request -> MSK.Timeout).
-- Modules WITH side effects (threads/events: Player, Callback, Vehicle, …) are
-- instead loaded EAGER in boot/* and set via rawset -> this __index never fires
-- for them (rawget hit). mountCore returns `false` for non-modules -> nil here,
-- so such keys can still be set later by eager modules.
--------------------------------------------------------------------------------
setmetatable(MSK, {
    __index = function(self, key)
        local mod = mountCore(key)
        if mod then
            rawset(self, key, mod)
            return mod
        end
        return nil
    end
})

--------------------------------------------------------------------------------
-- Export registry
-- Registers a public export whose function is resolved from the module only
-- on the first call (lazy-in-core).
--   name       : public export name      (e.g. 'Round')
--   moduleName : module folder           (e.g. 'math')
--   key        : key in the module's return value (e.g. 'Round'); nil = module itself
--
-- Called per module in the following batches, e.g.:
--   MSK.RegisterExport('Round', 'math', 'Round')
--------------------------------------------------------------------------------
local function registerExport(name, moduleName, key)
    exports(name, function(...)
        local mod = mountCore(moduleName)
        if not mod then
            error(("msk_core: export '%s' — module '%s' was not found."):format(name, moduleName), 2)
        end

        local fn = mod
        if key ~= nil then
            fn = mod[key]
            if fn == nil then
                error(("msk_core: export '%s' — key '%s' missing in module '%s'."):format(name, tostring(key), moduleName), 2)
            end
        end

        if type(fn) ~= 'function' then
            error(("msk_core: export '%s' does not point to a function (but %s)."):format(name, type(fn)), 2)
        end

        return fn(...)
    end)
end
MSK.RegisterExport = registerExport

--------------------------------------------------------------------------------
-- Logging
--------------------------------------------------------------------------------
MSK.Logging = function(code, ...)
    assert(code and type(code) == 'string', 'Parameter "code" has to be a string on function MSK.Logging')
    print(('[^2%s^0] %s'):format(GetInvokingResource() or 'msk_core', Config.LoggingTypes[code] or Config.LoggingTypes['debug']), ..., '^0')
end
MSK.logging = MSK.Logging -- Backwards compatibility
exports('Logging', MSK.Logging)

-- Core-internal, debug-gated logger (as in old — only in the msk_core runtime).
function logging(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end

--------------------------------------------------------------------------------
-- MSK.Call  =  pcall + Timeout.Await  (the Timeout module is loaded lazy-in-core)
--------------------------------------------------------------------------------
MSK.Call = function(fn, timeout)
    local Timeout = mountCore('timeout')
    if not Timeout then
        error("msk_core: MSK.Call requires the 'timeout' module (not yet ported).", 2)
    end
    return Timeout.Await(timeout or 1000, function()
        local ok, result = pcall(fn)
        if ok then return result end
    end)
end

--------------------------------------------------------------------------------
-- GetLib / getCoreObject  (legacy — return the core MSK table)
--------------------------------------------------------------------------------
local function GetLib()
    return MSK
end
exports('GetLib', GetLib)
exports('getCoreObject', GetLib) -- Support for old Versions

--------------------------------------------------------------------------------
-- Public exports of the core modules
-- Lazy-in-core: the respective module is loaded into the msk_core runtime only
-- on the first export call. Module folders are case-sensitive (= API key).
--------------------------------------------------------------------------------
-- Math
registerExport('GetRandomNumber', 'Math',    'Random')
registerExport('Round',           'Math',    'Round')
registerExport('Comma',           'Math',    'Comma')
-- String
registerExport('GetRandomString', 'String',  'Random')
registerExport('StartsWith',      'String',  'StartsWith')
registerExport('Trim',            'String',  'Trim')
registerExport('Split',           'String',  'Split')
-- Table
registerExport('TableContains',   'Table',   'Contains')
registerExport('TableDump',       'Table',   'Dump')
registerExport('TableDumpString', 'Table',   'DumpString')
registerExport('TableSize',       'Table',   'Size')
registerExport('TableIndex',      'Table',   'Index')
registerExport('TableLastIndex',  'Table',   'LastIndex')
registerExport('TableFind',       'Table',   'Find')
registerExport('TableReverse',    'Table',   'Reverse')
registerExport('TableClone',      'Table',   'Clone')
registerExport('TableSort',       'Table',   'Sort')
-- Timeout
registerExport('SetTimeout',      'Timeout', 'Set')
registerExport('ClearTimeout',    'Timeout', 'Clear')
registerExport('AwaitTimeout',    'Timeout', 'Await')
-- Vector
registerExport('CoordsToString',  'Vector',  'CoordsToString')
registerExport('VectorToVector',  'Vector',  'VectorToVector')
registerExport('TableToVector',   'Vector',  'TableToVector')

-- Lowercase backwards-compat alias: MSK.logging (consumer resolves via export proxy).
exports('logging', MSK.Logging)

--------------------------------------------------------------------------------
-- Scaleform exports — both sides: client draws, server triggers.
-- The registry wrapper loads the matching module file per side (client/server).
--------------------------------------------------------------------------------
registerExport('FreemodeMessage',   'Scaleform', 'FreemodeMessage')
registerExport('PopupWarning',      'Scaleform', 'PopupWarning')
registerExport('BreakingNews',      'Scaleform', 'BreakingNews')
registerExport('TrafficMovie',      'Scaleform', 'TrafficMovie')
registerExport('ScaleformAnnounce', 'Scaleform', 'ScaleformAnnounce')

-- (World functions are exported by the World module itself; it is loaded eager
--  in boot/{client,server}.lua, because core modules like Ban/Disconnect-Logger use MSK.AddWebhook.)

--------------------------------------------------------------------------------
-- hasLoaded (bootstrap correctness check: returns true if the core has 
-- finished loading, otherwise an error message)
-- Set to true at the end of boot/client.lua resp. boot/server.lua via
-- MSK.MarkLoaded().
--------------------------------------------------------------------------------
local ready = false

function MSK.MarkLoaded()
    ready = true
end

exports('hasLoaded', function()
    if ready then return true end
    return '^1msk_core has not finished loading yet.^0'
end)
