MSK = MSK or {}
MSK.Bridge = MSK.Bridge or {}
MSK.Bridge.Framework = MSK.Bridge.Framework or {}
MSK.Bridge.Players = MSK.Bridge.Players or {}
MSK.Bridge.PlayerData = {}
MSK.Bridge.isPlayerLoaded = false
MSK.LoadedPlayers = MSK.LoadedPlayers or {} -- server-side list of loaded framework players (maintained by the bridge)

-- Global event names (resource-independent, must be kept 1:1).
MSK.Bridge.Framework.Events = {
    setPlayerData = 'msk_core:setPlayerData',
    playerLoaded  = 'msk_core:playerLoaded',
    playerLogout  = 'msk_core:playerLogout',
    setJob        = 'msk_core:setJob',
}

local resourceName = GetCurrentResourceName()

--------------------------------------------------------------------------------
-- Framework detection
--------------------------------------------------------------------------------
if Config.Framework == 'AUTO' then
    if GetResourceState('es_extended') ~= 'missing' then
        Config.Framework = 'ESX'
    elseif GetResourceState('qb-core') ~= 'missing' then
        Config.Framework = 'QBCore'
    elseif GetResourceState('ox_core') ~= 'missing' then
        Config.Framework = 'OXCore'
    else
        Config.Framework = 'STANDALONE'
    end

    print(('[^2%s^0] [^4Info^0] Framework ^3%s^0 found'):format(resourceName, Config.Framework))
end

if Config.Framework == 'ESX' then
    local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
    if not ok or not core then
        error(("^1msk_core: ESX was detected, but the shared object could not be loaded. Does 'es_extended' start BEFORE msk_core?^0%s")
            :format(ok and '' or ('\n' .. tostring(core))), 0)
    end
    ESX = core
    MSK.Bridge.Framework.Type = 'ESX'
    MSK.Bridge.Framework.Core = ESX
elseif Config.Framework == 'QBCore' then
    local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if not ok or not core then
        error(("^1msk_core: QBCore was detected, but the core object could not be loaded. Does 'qb-core' start BEFORE msk_core?^0%s")
            :format(ok and '' or ('\n' .. tostring(core))), 0)
    end
    QBCore = core
    MSK.Bridge.Framework.Type = 'QBCore'
    MSK.Bridge.Framework.Core = QBCore
elseif Config.Framework == 'OXCore' then
    -- OXCore = "best effort" (project decision): the branch is kept,
    -- but focus/guarantee is on ESX/QBCore.
    MSK.Bridge.Framework.Type = 'OXCore'
    MSK.Bridge.Framework.Core = Ox or Citizen.Trace("^1SCRIPT ERROR: Please add '@ox_core/lib/init.lua' to the fxmanifest.lua^0\n")
else
    -- STANDALONE: deliberately do NOT load a framework-specific bridge.
    MSK.Bridge.Framework.Type = 'STANDALONE'
    if Config.Debug then
        print(('[^2%s^0] [^4Info^0] STANDALONE — no framework bridge loaded'):format(resourceName))
    end
end

--------------------------------------------------------------------------------
-- Inventory detection
--   AUTO   : auto-detect (ox_inventory > core_inventory > jaksam_inventory > default)
--   default: ESX default inventory / Chezza inventory (no FunctionOverride)
--   custom : your own implementation in inventories/custom.lua
--   Fully maintained: ox_inventory, jaksam_inventory
--   Still ported (secondary): core_inventory
--------------------------------------------------------------------------------
MSK.Bridge.Inventory = Config.Inventory

if Config.Inventory == 'AUTO' then
    if GetResourceState('ox_inventory') ~= 'missing' then
        MSK.Bridge.Inventory = 'ox_inventory'
    elseif GetResourceState('core_inventory') ~= 'missing' then
        MSK.Bridge.Inventory = 'core_inventory'
    elseif GetResourceState('jaksam_inventory') ~= 'missing' then
        MSK.Bridge.Inventory = 'jaksam_inventory'
    else
        MSK.Bridge.Inventory = 'default'
    end

    print(('[^2%s^0] [^4Info^0] Inventory ^3%s^0 found'):format(resourceName, MSK.Bridge.Inventory))
elseif Config.Debug then
    print(('[^2%s^0] [^4Info^0] Inventory ^3%s^0 found'):format(resourceName, MSK.Bridge.Inventory))
end
