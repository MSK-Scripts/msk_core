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

local function GetPlayerData(playerData)
    if not playerData then return end
    local self = playerData

    self.GetInventory = self.PlayerData.items
    self.AddItem = self.Functions.AddItem
    self.RemoveItem = self.Functions.RemoveItem
    self.HasItem = self.Functions.GetItemByName
    self.GetItem = self.Functions.GetItemByName
    -- self.CanSwapItem = self.PlayerData.Functions.CanSwapItem --> Not found in documentation
    --- self.CanCarryItem = self.Functions.CanCarryItem --> Not found in documentation
    self.AddMoney = self.Functions.AddMoney
    self.RemoveMoney = self.Functions.RemoveMoney
    self.AddWeapon = self.AddItem
    self.RemoveWeapon = self.RemoveItem
    self.HasWeapon = self.HasItem
    self.Set = self.Functions.SetMetaData
    self.Get = self.Functions.GetMetaData
    self.SetJob = self.Functions.SetJob

    self.identifier = self.PlayerData.citizenid
    self.source = self.PlayerData.source
    self.firstName = self.PlayerData.charinfo.firstname
    self.lastName = self.PlayerData.charinfo.lastname
    self.name = self.PlayerData.charinfo.firstname .. ' ' .. self.PlayerData.charinfo.lastname
    self.dob = self.PlayerData.charinfo.birthdate
    self.sex = self.PlayerData.charinfo.gender == 1 and 'male' or 'female'
    self.phone = self.PlayerData.charinfo.phone
    self.inventory = self.PlayerData.items

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

    if MSK.Bridge.Inventory ~= 'default' and FunctionOverride then
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
exports('GetServerId', MSK.GetPlayerServerId)

MSK.GetPlayerIdentifier = function(Player)
    if tonumber(Player) then
        local playerId = tostring(Player)
        local identifier = GetPlayerIdentifierByType(playerId, "license")
        return identifier and identifier:gsub("license:", "")
    end

    return Player.PlayerData.citizenid
end
MSK.GetIdentifier = MSK.GetPlayerIdentifier
exports('GetPlayerIdentifier', MSK.GetPlayerIdentifier)
exports('GetIdentifier', MSK.GetPlayerIdentifier)

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

    local Player = QBCore.Functions.GetPlayer(playerId)

    if type(itemName) ~= 'table' then
        local hasItem = Player.Functions.GetItemByName(itemName)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end

        return false
    end

    for i = 1, #itemName do
        local item = itemName[i]
        local hasItem = Player.Functions.GetItemByName(item)

        if hasItem and hasItem.count > 0 then
            return hasItem
        end
    end

    return false
end
exports('HasPlayerItem', MSK.HasPlayerItem)
