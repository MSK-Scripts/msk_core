MSK = {}
MSK.Bridge = {}
MSK.Bridge.Framework = {}
MSK.Bridge.Framework.Events = {
    setPlayerData = 'msk_core:setPlayerData',
    playerLoaded = 'msk_core:playerLoaded',
    playerLogout = 'msk_core:playerLogout',
    setJob = 'msk_core:setJob',
    onPlayerDeath = 'msk_core:onPlayerDeath',
}

if Config.Framework == 'AUTO' then
    if GetResourceState('es_extended') ~= 'missing' then
        Config.Framework = 'ESX'
    elseif GetResourceState('qb-core') ~= 'missing' then
        Config.Framework = 'QBCore'
    elseif GetResourceState('ox_core') ~= 'missing' then
        Config.Framework = 'OXCore'
    else
        Config.Framework = 'STANDALONE'
        MSK.Bridge.Framework.Type = 'STANDALONE'
    end

    print(('[^2%s^0] [^4Info^0] Framework ^3%s^0 found'):format(GetCurrentResourceName(), Config.Framework))
end

if Config.Framework == 'ESX' then
    ESX = exports["es_extended"]:getSharedObject()
    MSK.Bridge.Framework.Type = 'ESX'
    MSK.Bridge.Framework.Core = ESX
elseif Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
    MSK.Bridge.Framework.Type = 'QBCore'
    MSK.Bridge.Framework.Core = QBCore
elseif Config.Framework == 'OXCore' then
    MSK.Bridge.Framework.Type = 'OXCore'
    MSK.Bridge.Framework.Core = Ox or Citizen.Trace("^1SCRIPT ERROR: Please add '@ox_core/lib/init.lua' to the fxmanifest.lua^0\n")
end

MSK.Bridge.Inventory = Config.Inventory
if GetResourceState('ox_inventory') ~= 'missing' then
    MSK.Bridge.Inventory = 'ox_inventory'
elseif GetResourceState('qs-inventory') ~= 'missing' then
    MSK.Bridge.Inventory = 'qs-inventory'
end

MSK.Bridge.isPlayerLoaded = false

if MSK.Bridge.Framework.Type == 'ESX' then
    RegisterNetEvent('esx:setPlayerData', function(key, val)
        TriggerEvent(MSK.Bridge.Framework.Events.setPlayerData, MSK.Bridge.Player)
        TriggerServerEvent(MSK.Bridge.Framework.Events.setPlayerData)
    end)

    RegisterNetEvent('esx:playerLoaded', function(xPlayer, isNew, skin)
        MSK.Bridge.isPlayerLoaded = true
        TriggerEvent(MSK.Bridge.Framework.Events.playerLoaded, MSK.Bridge.Player)
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        MSK.Bridge.isPlayerLoaded = false
        TriggerEvent(MSK.Bridge.Framework.Events.playerLogout)
    end)

    RegisterNetEvent('esx:setJob', function(newJob, lastJob)
        TriggerEvent(MSK.Bridge.Framework.Events.setJob, MSK.Bridge.Player, newJob, lastJob)
    end)
elseif MSK.Bridge.Framework.Type == 'QBCore' then
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
        TriggerEvent(MSK.Bridge.Framework.Events.setPlayerData, MSK.Bridge.Player)
        TriggerServerEvent(MSK.Bridge.Framework.Events.setPlayerData)
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        MSK.Bridge.isPlayerLoaded = true
        TriggerEvent(MSK.Bridge.Framework.Events.playerLoaded, MSK.Bridge.Player)
        TriggerServerEvent(MSK.Bridge.Framework.Events.playerLoaded)
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        MSK.Bridge.isPlayerLoaded = false
        TriggerEvent(MSK.Bridge.Framework.Events.playerLogout)
        TriggerServerEvent(MSK.Bridge.Framework.Events.playerLogout)
    end)

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(newJob)
        TriggerEvent(MSK.Bridge.Framework.Events.setJob, MSK.Bridge.Player, newJob)
        TriggerServerEvent(MSK.Bridge.Framework.Events.playerLogout, newJob)
    end)
end

local GetLib = function()
    return MSK
end
exports('GetLib', GetLib)
exports('getCoreObject', GetLib) -- Support for old Versions
