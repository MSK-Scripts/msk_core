if MSK.Bridge.Framework.Type ~= 'ESX' then return end

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLoaded, function(playerId, xPlayer, isNew)
    MSK.LoadedPlayers[playerId] = xPlayer
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLogout, function(playerId)
    MSK.LoadedPlayers[playerId] = nil
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setJob, function(playerId, newJob, lastJob)
    MSK.LoadedPlayers[playerId].job = newJob
end)

GetPlayerData = function(playerData)
    local self = playerData

    self.GetInventory = playerData.getInventory
    self.AddItem = playerData.addInventoryItem
    self.RemoveItem = playerData.removeInventoryItem
    self.HasItem = playerData.hasItem
    self.GetItem = playerData.getInventoryItem
    self.CanSwapItem = playerData.canSwapItem
    self.CanCarryItem = playerData.canCarryItem
    self.AddMoney = playerData.addAccountMoney
    self.RemoveMoney = playerData.removeAccountMoney
    self.AddWeapon = playerData.addWeapon
    self.RemoveWeapon = playerData.removeWeapon
    self.HasWeapon = playerData.hasWeapon
    self.Set = playerData.setMeta
    self.Get = playerData.getMeta
    self.SetJob = playerData.setJob

    self.dob = playerData.dateofbirth

    local job = self.job
    self.job = {
        name = job.name,
        label = job.name,
        grade = job.grade,
        grade_name = job.grade_name,
        grade_label = job.grade_label,
        grade_salary = job.grade_salary,
        isBoss = job.grade_name == 'boss'
    }

    self.Notification = function(title, message, typ, duration)
        MSK.Notification(self.source, title, message, typ, duration)
    end
    self.Notify = self.Notification

    self.GetAccount = function(account)
        for i = 1, #self.accounts do
			if self.accounts[i].name == account:lower() then
				return self.accounts[i]
			end
		end
		return nil
    end

    if MSK.Bridge.Inventory ~= 'default' then
        self = FunctionOverride(self)
    end

    return self
end

MSK.GetPlayer = function(player, data)
    local Player

    if player.player then
        Player = player.player
    elseif player.source then
        Player = ESX.GetPlayerFromId(player.source)
    elseif player.identifier then
        Player = ESX.GetPlayerFromIdentifier(player.identifier)
    elseif player.citizenid then
        Player = ESX.GetPlayerFromIdentifier(player.citizenid)
    elseif player.phone then
        Player = nil
    end

    if data == nil then data = true end

    return data and GetPlayerData(Player) or Player
end
exports('GetPlayer', MSK.GetPlayer)

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

MSK.GetPlayerJob = function(player)
    local Player = MSK.GetPlayer(player, false)
    return Player.job.name
end
exports('GetPlayerJob', MSK.GetPlayerJob)

MSK.HasPlayerItem = function(playerId, itemName)
    if not playerId then 
        MSK.Logging('error', 'Player on Function MSK.HasItem does not exist!') 
        return false
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if type(itemName) ~= 'table' then
        local hasItem = xPlayer.getInventoryItem(itemName)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end

        return false
    end

    for i = 1, #itemName do
        local item = itemName[i]
        local hasItem = xPlayer.getInventoryItem(itemName)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end
    end
    
    return false
end