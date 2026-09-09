MSK = MSK or {}
MSK.Bridge = MSK.Bridge or {}
MSK.Bridge.Framework = MSK.Bridge.Framework or {}
MSK.Bridge.Players = MSK.Bridge.Players or {}
MSK.Bridge.PlayerData = {}
MSK.Bridge.isPlayerLoaded = false

-- Server-side map of loaded players: playerId -> MskPlayer.
-- Filled by the neutral bridge layer (bridge/server.lua), never by an adapter.
MSK.LoadedPlayers = MSK.LoadedPlayers or {}

--------------------------------------------------------------------------------
-- Public event names (resource-independent, identical on every framework).
-- The names are API and stay 1:1. Their ARGUMENTS changed in 4.0.0: every
-- payload is now the unified MskPlayer / MskJob shape, never the raw framework
-- object.
--
--   server  msk_core:playerLoaded  (playerId, MskPlayer)
--           msk_core:playerLogout  (playerId)
--           msk_core:setJob        (playerId, MskJob, lastJob)
--           msk_core:setGang       (playerId, MskJob, lastGang)
--           msk_core:setDuty       (playerId, onDuty, MskJob)
--
--   client  msk_core:playerLoaded  (MskPlayer)
--           msk_core:playerLogout  ()
--           msk_core:setJob        (MskJob, lastJob)
--           msk_core:setGang       (MskJob, lastGang)
--           msk_core:setDuty       (onDuty, MskJob)
--           msk_core:setPlayerData (MskPlayer)
--------------------------------------------------------------------------------
MSK.Bridge.Framework.Events = {
    setPlayerData = 'msk_core:setPlayerData',
    playerLoaded  = 'msk_core:playerLoaded',
    playerLogout  = 'msk_core:playerLogout',
    setJob        = 'msk_core:setJob',
    setGang       = 'msk_core:setGang',
    setDuty       = 'msk_core:setDuty',
}

local resourceName = GetCurrentResourceName()

local function resourceExists(name)
    return GetResourceState(name) ~= 'missing'
end

--------------------------------------------------------------------------------
-- Framework detection
--
-- Every framework is looked up under its OWN resource name, and Qbox is checked
-- BEFORE QBCore. Reason: qbx_core/fxmanifest.lua declares `provide 'qb-core'`,
-- so GetResourceState('qb-core') does not report 'missing' on a Qbox server.
-- Checking qb-core first pushes every Qbox server into the QBCore branch and
-- through its compatibility layer, which cannot represent Qbox multijob
-- (PlayerData.jobs) at all.
--
-- A `provide` hit is a fallback, never a detection. FiveM changed how provided
-- names answer resource-state lookups twice during 2026 (builds b90 and b95),
-- and for two weeks GetResourceState returned 'missing' for a provided name
-- without a single line of script code having changed.
-- See https://github.com/citizenfx/rfc/discussions/15
--------------------------------------------------------------------------------
if Config.Framework == 'OXCore' then
    error(("^1%s: Config.Framework = 'OXCore' is no longer supported, the ox_core branch was removed in 4.0.0. Set Config.Framework to AUTO, ESX, QBCore, Qbox or STANDALONE.^0")
        :format(resourceName), 0)
end

if Config.Framework == 'AUTO' then
    if resourceExists('qbx_core') then
        Config.Framework = 'Qbox'
    elseif resourceExists('es_extended') then
        Config.Framework = 'ESX'
    elseif resourceExists('qb-core') then
        Config.Framework = 'QBCore'
    else
        Config.Framework = 'STANDALONE'
    end

    print(('[^2%s^0] [^4Info^0] Framework ^3%s^0 found'):format(resourceName, Config.Framework))
end

MSK.Bridge.Framework.Type = Config.Framework

if Config.Framework == 'ESX' then
    local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
    if not ok or not core then
        error(("^1%s: ESX was detected, but the shared object could not be loaded. Does 'es_extended' start BEFORE %s?^0%s")
            :format(resourceName, resourceName, ok and '' or ('\n' .. tostring(core))), 0)
    end
    ESX = core
    MSK.Bridge.Framework.Core = ESX
elseif Config.Framework == 'QBCore' then
    local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if not ok or not core then
        error(("^1%s: QBCore was detected, but the core object could not be loaded. Does 'qb-core' start BEFORE %s?^0%s")
            :format(resourceName, resourceName, ok and '' or ('\n' .. tostring(core))), 0)
    end
    QBCore = core
    MSK.Bridge.Framework.Core = QBCore
elseif Config.Framework == 'Qbox' then
    -- Qbox has no core object, everything runs through exports.qbx_core. That
    -- export table is what MSK.Bridge.Framework.Core points at, so consumers
    -- have one place to reach the framework on every branch.
    if not resourceExists('qbx_core') then
        error(("^1%s: Config.Framework = 'Qbox', but the resource 'qbx_core' was not found.^0"):format(resourceName), 0)
    end
    QBX = exports.qbx_core
    MSK.Bridge.Framework.Core = QBX
elseif Config.Framework == 'STANDALONE' then
    -- STANDALONE deliberately loads no framework bridge at all.
    if Config.Debug then
        print(('[^2%s^0] [^4Info^0] STANDALONE - no framework bridge loaded'):format(resourceName))
    end
else
    error(("^1%s: unknown Config.Framework '%s'. Allowed: AUTO, ESX, QBCore, Qbox, STANDALONE.^0")
        :format(resourceName, tostring(Config.Framework)), 0)
end

--------------------------------------------------------------------------------
-- Adapter contract
--
-- Each bridge/<framework>/{server,client}.lua fills this table, the neutral
-- layer in bridge/{server,client}.lua consumes it. Adapters never build the
-- public player object themselves and never write to the framework's own
-- objects, so ESX keeps its xPlayer.job and QBCore keeps its PlayerData.
--
-- Server adapter keys:
--   events          table          real framework event names
--   getBySource     fn(playerId)   -> raw|nil
--   getByIdentifier fn(identifier) -> raw|nil
--   getByPhone      fn(phone)      -> raw|nil
--   getByUserId     fn(userId)     -> raw|nil   (Qbox only, nil elsewhere)
--   getAll          fn()           -> raw[]
--   read            fn(raw)        -> unified field table
--   plus the write functions consumed by bridge/server.lua
--------------------------------------------------------------------------------
MSK.Bridge.Adapter = MSK.Bridge.Adapter or {}

--------------------------------------------------------------------------------
-- Shared helper for job and gang definitions
--
-- Every framework stores grades differently: ESX keys them by grade and repeats
-- the number inside, QBCore and Qbox key them by grade with the number only in
-- the key, and the pay field is called salary on one side and payment on the
-- other. Normalising that here means an adapter only has to hand over what its
-- framework gave it.
--
-- Result is a list sorted by grade:
--   { { grade = 0, name = 'recruit', label = 'Recruit', salary = 50, isBoss = false }, ... }
--------------------------------------------------------------------------------
function MSK.Bridge.NormaliseGrades(grades)
    local list = {}

    for key, grade in pairs(grades or {}) do
        if type(grade) == 'table' then
            local number = tonumber(grade.grade) or tonumber(key) or 0

            list[#list + 1] = {
                grade  = math.floor(number),
                name   = grade.name or tostring(number),
                label  = grade.label or grade.name or tostring(number),
                salary = tonumber(grade.salary or grade.payment) or 0,
                isBoss = grade.isboss or grade.isBoss or false,
            }
        end
    end

    table.sort(list, function(a, b) return a.grade < b.grade end)

    return list
end

--------------------------------------------------------------------------------
-- Inventory adapter contract
--
-- Filled by inventories/server/<inventory>.lua. Framework and inventory are two
-- independent axes, so no framework bridge carries item code and no inventory
-- adapter carries framework code. inventories/server/default.lua covers the
-- inventory built into the running framework.
--
-- Every function takes the server id first, never a framework player object:
--   getInventory(playerId)                              -> table
--   getItem(playerId, name, metadata)                   -> item|nil
--   addItem(playerId, name, count, metadata, slot)      -> boolean
--   removeItem(playerId, name, count, metadata, slot)   -> boolean
--   addWeapon / removeWeapon / getWeapon                same shape
--   canCarryItem(playerId, name, count, metadata)       -> boolean|nil
--   canSwapItem(playerId, a, aCount, b, bCount)         -> boolean|nil
--   setMaxWeight(playerId, kilograms)                   -> boolean|nil
--
-- nil means "this inventory cannot answer that", which is not the same as
-- false. Reporting true without checking is what makes items disappear.
--------------------------------------------------------------------------------
MSK.Bridge.InventoryAdapter = MSK.Bridge.InventoryAdapter or {}

--------------------------------------------------------------------------------
-- Inventory detection
--   AUTO   : auto-detect (ox_inventory > core_inventory > jaksam_inventory > default)
--   default: ESX default inventory / Chezza inventory (no FunctionOverride)
--   custom : your own implementation in inventories/server/custom.lua
--   Fully maintained: ox_inventory, jaksam_inventory
--   Still ported (secondary): core_inventory
--------------------------------------------------------------------------------
MSK.Bridge.Inventory = Config.Inventory

if Config.Inventory == 'AUTO' then
    if resourceExists('ox_inventory') then
        MSK.Bridge.Inventory = 'ox_inventory'
    elseif resourceExists('core_inventory') then
        MSK.Bridge.Inventory = 'core_inventory'
    elseif resourceExists('jaksam_inventory') then
        MSK.Bridge.Inventory = 'jaksam_inventory'
    else
        MSK.Bridge.Inventory = 'default'
    end

    print(('[^2%s^0] [^4Info^0] Inventory ^3%s^0 found'):format(resourceName, MSK.Bridge.Inventory))
elseif Config.Debug then
    print(('[^2%s^0] [^4Info^0] Inventory ^3%s^0 found'):format(resourceName, MSK.Bridge.Inventory))
end

-- Qbox ships ox_inventory. 'default' means the ESX/Chezza inventory, which does
-- not exist there, so say it now instead of failing on the first item call.
if MSK.Bridge.Framework.Type == 'Qbox' and MSK.Bridge.Inventory == 'default' then
    print(('[^2%s^0] [^3Warning^0] Framework is Qbox but no supported inventory was found. Item functions stay unavailable until ox_inventory runs.'):format(resourceName))
end

--------------------------------------------------------------------------------
-- Bridge info for consumers
--
-- MSK.Bridge is a table inside msk_core only. In a consumer, import.lua has no
-- module and no alias called 'Bridge', so it falls through to the generic
-- export proxy and MSK.Bridge becomes a FUNCTION. Reading MSK.Bridge.Framework
-- there raises "attempt to index a function value", which is what happens in
-- every 3.x script carrying the line
--     if MSK.Bridge and MSK.Bridge.Framework and ...
--
-- modules/Bridge/shared.lua turns that back into a real table in the consumer,
-- and it reads what it needs from here.
--------------------------------------------------------------------------------
exports('GetBridgeInfo', function()
    return {
        framework = MSK.Bridge.Framework.Type,
        inventory = MSK.Bridge.Inventory,
        events    = MSK.Bridge.Framework.Events,
    }
end)
