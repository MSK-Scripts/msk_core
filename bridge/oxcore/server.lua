if MSK.Bridge.Framework.Type ~= 'OXCore' then return end

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLoaded, function(playerId, userId, charId)
    MSK.LoadedPlayers[playerId] = Ox.GetPlayer(playerId)
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLogout, function(playerId, userId, charId)
    MSK.LoadedPlayers[playerId] = nil
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setJob, function(playerId, groupName, grade)
    if not MSK.LoadedPlayers[playerId].job then
        MSK.LoadedPlayers[playerId].job = {}
    end

    MSK.LoadedPlayers[playerId].job[groupName] = grade
end)

GetPlayerData = function(playerData)
end

MSK.GetPlayerServerId = function(Player)
    return Player.source
end
MSK.GetServerId = MSK.GetPlayerServerId
exports('GetPlayerServerId', MSK.GetPlayerServerId)

MSK.GetPlayerIdentifier = function(Player)
    if tonumber(Player) then
        playerId = tostring(Player)
        local identifier = GetPlayerIdentifierByType(playerId, "license")
        return identifier and identifier:gsub("license:", "")
    end

    return Player.identifier
end
MSK.GetIdentifier = MSK.GetPlayerIdentifier
exports('GetPlayerIdentifier', MSK.GetPlayerIdentifier)

MSK.HasPlayerItem = function(playerId, itemName, metadata)
    if not playerId then 
        MSK.Logging('error', 'Player on Function MSK.HasItem does not exist!') 
        return false
    end
    
    if type(itemName) ~= 'table' then
        local hasItem = exports.ox_inventory:GetItem(playerId, itemName, metadata)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end

        return false
    end

    for i = 1, #itemName do
        local item = itemName[i]
        local hasItem = exports.ox_inventory:GetItem(playerId, itemName, metadata)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end
    end
    
    return false
end