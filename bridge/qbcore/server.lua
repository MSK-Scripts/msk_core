if MSK.Bridge.Framework.Type ~= 'QBCore' then return end

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLoaded, function(playerId)
    MSK.LoadedPlayers[playerId] = QBCore.Functions.GetPlayer(playerId)
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLogout, function(playerId)
    MSK.LoadedPlayers[playerId] = nil
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setJob, function(playerId, newJob)
    MSK.LoadedPlayers[playerId].job = newJob
end)

GetPlayerData = function(playerData)
    local self = playerData

    self.GetInventory = Player.PlayerData.items
    self.AddItem = Player.Functions.AddItem
    self.RemoveItem = Player.Functions.RemoveItem
    self.HasItem = Player.Functions.GetItemByName
    self.GetItem = Player.Functions.GetItemByName
    -- self.CanSwapItem = Player.Functions.CanSwapItem --> Not found in documentation
    --- self.CanCarryItem = Player.Functions.CanCarryItem --> Not found in documentation
    self.AddMoney = Player.Functions.AddMoney
    self.RemoveMoney = Player.Functions.RemoveMoney
    self.AddWeapon = Player.AddItem
    self.RemoveWeapon = Player.RemoveItem
    self.HasWeapon = Player.HasItem
    self.Set = Player.Functions.SetMetaData
    self.Get = Player.Functions.GetMetaData
    self.SetJob = Player.Functions.SetJob

    self.identifier = Player.PlayerData.citizenid
    self.source = Player.PlayerData.source
    self.firstName = Player.PlayerData.charinfo.firstname
    self.lastName = Player.PlayerData.charinfo.lastname
    self.name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    self.dob = Player.PlayerData.charinfo.birthdate
    self.sex = Player.PlayerData.charinfo.gender == 1 and 'male' or 'female'
    self.phone = Player.PlayerData.charinfo.phone
    self.inventory = Player.PlayerData.items

    local job = self.PlayerData.job
    self.job = {
        name = job.name,
        label = job.label,
        grade = job.grade.level,
        grade_name = job.grade.name,
        grade_label = job.grade.name,
        grade_salary = job.payment,
        isBoss = job.isboss
    }

    self.accounts = {
        money = {name = 'money', money = self.PlayerData.money['cash']},
        black_money = {name = 'black_money', money = self.PlayerData.money['black_money']},
        bank = {name = 'bank', money = self.PlayerData.money['bank']},
    }

    self.Notification = function(title, message, typ, duration)
        MSK.Notification(self.source, title, message, typ, duration)
    end
    self.Notify = self.Notification

    self.GetAccount = function(account)
        return self.accounts[account:lower()]
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
        Player = QBCore.Functions.GetPlayer(player.source)
    elseif player.identifier then
        Player = QBCore.Functions.GetPlayerByCitizenId(player.identifier)
    elseif player.citizenid then
        Player = QBCore.Functions.GetPlayerByCitizenId(player.citizenid)
    elseif player.phone then
        Player = QBCore.Functions.GetPlayerByPhone(tostring(player.phone))
    end

    if data == nil then data = true end

    return data and GetPlayerData(Player) or Player
end
exports('GetPlayer', MSK.GetPlayer)

MSK.GetPlayerServerId = function(Player)
    return Player.PlayerData.source
end
MSK.GetServerId = MSK.GetPlayerServerId
exports('GetPlayerServerId', MSK.GetPlayerServerId)

MSK.GetPlayerIdentifier = function(Player)
    if tonumber(Player) then
        playerId = tostring(Player)
        local identifier = GetPlayerIdentifierByType(playerId, "license")
        return identifier and identifier:gsub("license:", "")
    end

    return Player.PlayerData.citizenid
end
MSK.GetIdentifier = MSK.GetPlayerIdentifier
exports('GetPlayerIdentifier', MSK.GetPlayerIdentifier)

MSK.GetPlayerJob = function(player)
    local Player = MSK.GetPlayer(player, false)
    return Player.PlayerData.job.name
end
exports('GetPlayerJob', MSK.GetPlayerJob)

MSK.HasPlayerItem = function(playerId, itemName)
    if not playerId then 
        MSK.Logging('error', 'Player on Function MSK.HasItem does not exist!') 
        return false
    end

    local Player = QBCore.Functions.GetPlayer(player.source)
    
    if type(itemName) ~= 'table' then
        local hasItem = Player.Functions.GetItemByName(itemName)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end

        return false
    end

    for i = 1, #itemName do
        local item = itemName[i]
        local hasItem = Player.Functions.GetItemByName(itemName)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end
    end
    
    return false
end