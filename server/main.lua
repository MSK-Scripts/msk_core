MSK = {}
MSK.Bridge = {}
MSK.Bridge.Framework = {}
MSK.Bridge.Players = {}
MSK.Bridge.Framework.Events = {
    playerLoaded = 'msk_core:playerLoaded',
    playerLogout = 'msk_core:playerLogout',
    setJob = 'msk_core:setJob',
}

if Config.Framework == 'AUTO' then
    if GetResourceState('es_extended') ~= 'missing' then
        ESX = exports["es_extended"]:getSharedObject()
        MSK.Bridge.Framework.Type = 'ESX'
        MSK.Bridge.Framework.Core = ESX
    elseif GetResourceState('qb-core') ~= 'missing' then
        QBCore = exports['qb-core']:GetCoreObject()
        MSK.Bridge.Framework.Type = 'QBCore'
        MSK.Bridge.Framework.Core = QBCore
    end
    print(('[^2%s^0] [^4Info^0] Framework ^3%s^0 found'):format(GetCurrentResourceName(), MSK.Bridge.Framework.Type))
elseif Config.Framework == 'ESX' then
    ESX = exports["es_extended"]:getSharedObject()
    MSK.Bridge.Framework.Type = 'ESX'
    MSK.Bridge.Framework.Core = ESX
elseif Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
    MSK.Bridge.Framework.Type = 'QBCore'
    MSK.Bridge.Framework.Core = QBCore
end

MSK.Bridge.Inventory = Config.Inventory
if GetResourceState('ox_inventory') ~= 'missing' then
    MSK.Bridge.Inventory = 'ox_inventory'
    print(('[^2%s^0] [^4Info^0] Inventory ^3ox_inventory^0 found'):format(GetCurrentResourceName()))
elseif GetResourceState('qs-inventory') ~= 'missing' then
    MSK.Bridge.Inventory = 'qs-inventory'
    print(('[^2%s^0] [^4Info^0] Inventory ^3qs-inventory^0 found'):format(GetCurrentResourceName()))
end

if MSK.Bridge.Framework.Type == 'ESX' then
    RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer, isNew)
        TriggerEvent(MSK.Bridge.Framework.Events.playerLoaded, playerId)
    end)

    RegisterNetEvent('esx:playerLogout', function(playerId)
        TriggerEvent(MSK.Bridge.Framework.Events.playerLogout, playerId)
    end)

    RegisterNetEvent('esx:setJob', function(playerId, newJob, lastJob)
        TriggerEvent(MSK.Bridge.Framework.Events.setJob, playerId, newJob, lastJob)
    end)
elseif MSK.Bridge.Framework.Type == 'QBCore' then
    -- Nothing to add here
end

MSK.GetPlayerFromId = function(playerId)
    return MSK.GetPlayer({source = playerId})
end
exports('GetPlayerFromId', MSK.GetPlayerFromId)

MSK.GetPlayerFromIdentifier = function(identifier)
    return MSK.GetPlayer({identifier = identifier})
end
exports('GetPlayerFromIdentifier', MSK.GetPlayerFromIdentifier)

MSK.GetPlayerByCitizenId = function(citizenid)
    return MSK.GetPlayer({citizenid = citizenid})
end
exports('GetPlayerByCitizenId', MSK.GetPlayerByCitizenId)

MSK.GetPlayerJobFromId = function(playerId)
    return MSK.GetPlayerJob({source = playerId})
end
exports('GetPlayerJobFromId', MSK.GetPlayerJobFromId)

MSK.GetPlayerJobFromIdentifier = function(identifier)
    return MSK.GetPlayerJob({identifier = identifier})
end
exports('GetPlayerJobFromIdentifier', MSK.GetPlayerJobFromIdentifier)

MSK.GetPlayerJobByCitizenId = function(citizenid)
    return MSK.GetPlayerJob({citizenid = citizenid})
end
exports('GetPlayerJobByCitizenId', MSK.GetPlayerJobByCitizenId)

MSK.GetPlayers = function(key, val)
    local Players

    if MSK.Bridge.Framework.Type == 'ESX' then
        Players = ESX.GetExtendedPlayers(key, val)
    elseif MSK.Bridge.Framework.Type == 'QBCore' then
        if not key then 
            Players = QBCore.Functions.GetQBPlayers()
        else
            local qbPlayers = {}

            for k, Player in pairs(QBCore.Functions.GetQBPlayers()) do
                if key == 'job' then
                    if Player.PlayerData.job.name == val then
                        qbPlayers[#qbPlayers + 1] = Player
                    end
                elseif key == 'gang' then
                    if Player.PlayerData.gang.name == val then
                        qbPlayers[#qbPlayers + 1] = Player
                    end
                elseif key == 'group' then
                    if IsPlayerAceAllowed(Player.PlayerData.source, val) then
                        qbPlayers[#qbPlayers + 1] = Player
                    end
                end
            end

            Players = qbPlayers
        end
    end

    return Players
end
exports('GetPlayers', MSK.GetPlayers)

GetLib = function()
    return MSK
end
exports('GetLib', GetLib)
exports('getCoreObject', GetLib) -- Support for old Versions