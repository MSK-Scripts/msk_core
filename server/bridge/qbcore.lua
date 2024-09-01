if MSK.Bridge.Framework.Type ~= 'QBCore' then return end

GetPlayerData = function(Player)
    Player.GetInventory = Player.PlayerData.items
    Player.AddItem = Player.Functions.AddItem
    Player.RemoveItem = Player.Functions.RemoveItem
    Player.HasItem = QBCore.Functions.HasItem
    Player.GetItem = Player.Functions.GetItemsByName
    -- Player.CanSwapItem = Player.Functions.CanSwapItem --> Not found in documentation
    -- Player.CanCarryItem = Player.Functions.CanCarryItem --> Not found in documentation
    Player.AddMoney = Player.Functions.AddMoney
    Player.RemoveMoney = Player.Functions.RemoveMoney
    Player.AddWeapon = Player.AddItem
    Player.RemoveWeapon = Player.RemoveItem
    Player.HasWeapon = Player.HasItem
    Player.SetMeta = Player.Functions.SetMetaData
    Player.GetMeta = Player.Functions.GetMetaData
    Player.SetJob = Player.Functions.SetJob

    Player.identifier = Player.PlayerData.citizenid
    Player.source = Player.PlayerData.source
    Player.firstName = Player.PlayerData.charinfo.firstname
    Player.lastName = Player.PlayerData.charinfo.lastname
    Player.name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    Player.dob = Player.PlayerData.charinfo.birthdate
    Player.sex = Player.PlayerData.charinfo.gender == 1 and 'male' or 'female'
    Player.phone = Player.PlayerData.charinfo.phone
    Player.inventory = Player.PlayerData.items

    Player.accounts = {
        money = {name = 'money', money = Player.PlayerData.money['cash']},
        black_money = {name = 'black_money', money = Player.PlayerData.money['black_money']},
        bank = {name = 'bank', money = Player.PlayerData.money['bank']},
    }

    local job = Player.PlayerData.job
    Player.job = {
        name = job.name,
        label = job.label,
        grade = job.grade.level,
        grade_name = job.grade.name,
        grade_label = job.grade.name,
        grade_salary = job.payment,
        isBoss = job.isboss
    }

    Player.Notification = function(title, message, typ, duration)
        MSK.Notification(Player.source, title, message, typ, duration)
    end
    Player.Notify = Player.Notification

    Player.GetAccount = function(account)
        return Player.accounts[account:lower()]
    end

    if MSK.Bridge.Inventory == 'ox_inventory' then
        Player = FunctionOverride(Player)
    elseif MSK.Bridge.Inventory == 'custom' then
        Player = FunctionOverride(Player)
    end

    return Player
end

MSK.GetPlayer = function(player)
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

    return GetPlayerData(Player)
end
exports('GetPlayer', MSK.GetPlayer)

MSK.GetServerIdFromPlayer = function(Player)
    return Player.PlayerData.source
end
MSK.GetServerId = MSK.GetServerIdFromPlayer
exports('GetServerIdFromPlayer', MSK.GetServerIdFromPlayer)

MSK.GetIdentifierFromPlayer = function(Player)
    return Player.PlayerData.citizenid
end
MSK.GetIdentifier = MSK.GetIdentifierFromPlayer
exports('GetIdentifierFromPlayer', MSK.GetIdentifierFromPlayer)

MSK.GetPlayerJob = function(player)
    local Player = MSK.GetPlayer(player)
    return Player.PlayerData.job.name
end
exports('GetPlayerJob', MSK.GetPlayerJob)