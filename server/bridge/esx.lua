if MSK.Bridge.Framework.Type ~= 'ESX' then return end

local GetPlayerData = function(Player)
    Player.GetInventory = Player.inventory
    Player.AddItem = Player.addInventoryItem
    Player.RemoveItem = Player.removeInventoryItem
    Player.HasItem = Player.hasItem
    Player.GetItem = Player.getInventoryItem
    Player.CanSwapItem = Player.canSwapItem
    Player.CanCarryItem = Player.canCarryItem
    Player.AddMoney = Player.addAccountMoney
    Player.RemoveMoney = Player.removeAccountMoney
    Player.AddWeapon = Player.addWeapon
    Player.RemoveWeapon = Player.removeWeapon
    Player.HasWeapon = Player.hasWeapon
    Player.SetMeta = Player.setMeta
    Player.GetMeta = Player.getMeta
    Player.SetJob = Player.setJob

    Player.dob = Player.dateofbirth

    local job = Player.job
    Player.job = {
        name = job.name,
        label = job.name,
        grade = job.grade,
        grade_name = job.grade_name,
        grade_label = job.grade_label,
        grade_salary = job.grade_salary,
        isBoss = job.grade_name == 'boss'
    }

    Player.Notification = function(title, message, typ, duration)
        MSK.Notification(Player.source, title, message, typ, duration)
    end
    Player.Notify = Player.Notification

    Player.GetAccount = function(account)
        for i = 1, #Player.accounts do
			if Player.accounts[i].name == account then
				return Player.accounts[i]
			end
		end
		return nil
    end

    if MSK.Bridge.Inventory ~= 'default' then
        Player = FunctionOverride(Player)
    end

    return Player
end

MSK.GetPlayer = function(player)
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

    return GetPlayerData(Player)
end
exports('GetPlayer', MSK.GetPlayer)

MSK.GetServerIdFromPlayer = function(Player)
    return Player.source
end
MSK.GetServerId = MSK.GetServerIdFromPlayer
exports('GetServerIdFromPlayer', MSK.GetServerIdFromPlayer)

MSK.GetIdentifierFromPlayer = function(Player)
    return Player.identifier
end
MSK.GetIdentifier = MSK.GetIdentifierFromPlayer
exports('GetIdentifierFromPlayer', MSK.GetIdentifierFromPlayer)

MSK.GetPlayerJob = function(player)
    local Player = MSK.GetPlayer(player)
    return Player.job.name
end
exports('GetPlayerJob', MSK.GetPlayerJob)