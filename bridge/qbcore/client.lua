if MSK.Bridge.Framework.Type ~= 'QBCore' then return end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    local playerData = QBCore.Functions.GetPlayerData()

    if playerData then
        MSK.Bridge.isPlayerLoaded = true
        QBCore.PlayerLoaded = true

        QBCore.PlayerData = playerData
        MSK.Bridge.PlayerData = playerData

        SetPlayerData()
    end
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setPlayerData, function(PlayerData)
    local invoke = GetInvokingResource()
    if not invoke or invoke ~= 'msk_core' then return end

    MSK.Bridge.PlayerData = PlayerData
    QBCore.PlayerData = PlayerData

    SetPlayerData()
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLoaded, function()
    MSK.Bridge.isPlayerLoaded = true
    QBCore.PlayerLoaded = true

    local playerData = QBCore.Functions.GetPlayerData()
    MSK.Bridge.PlayerData = playerData
    QBCore.PlayerData = playerData

    SetPlayerData()
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLogout, function()
    MSK.Bridge.isPlayerLoaded = false
    QBCore.PlayerLoaded = false

    MSK.Bridge.PlayerData = {}
    QBCore.PlayerData = {}
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setJob, function(newJob)
    MSK.Bridge.PlayerData.job = newJob
    SetPlayerData()
end)

MSK.Bridge.SetPlayerData = function(key, value)
    MSK.Bridge.PlayerData[key] = value
    QBCore.Functions.SetMetaData(key, val)
    SetPlayerData()
end

SetPlayerData = function()
    local self = MSK.Bridge.PlayerData

    self.identifier = self.PlayerData.citizenid
    self.firstName = self.PlayerData.charinfo.firstname
    self.lastName = self.PlayerData.charinfo.lastname
    self.name = self.PlayerData.charinfo.firstname .. ' ' .. self.PlayerData.charinfo.lastname
    self.dob = self.PlayerData.charinfo.birthdate
    self.sex = self.PlayerData.charinfo.gender == 1 and 'male' or 'female'
    self.phone = self.PlayerData.charinfo.phone
    self.metadata = self.PlayerData.metadata
    self.inventory = self.PlayerData.items

    local job = self.PlayerData.job
    self.job = {
        name = job.name,
        label = job.label,
        grade = job.grade.level,
        grade_name = job.grade.name,
        grade_label = job.grade.name,
        grade_salary = job.payment,
        isBoss = job.isboss,
    }

    if MSK.Bridge.Inventory == 'ox_inventory' then
        self.inventory = exports.ox_inventory:GetPlayerItems()
        self.loadout = self.inventory
    elseif MSK.Bridge.Inventory == 'qs-inventory' then
        self.inventory = exports['qs-inventory']:getUserInventory()
        self.loadout = self.inventory
    end

    self.Notification = function(title, message, typ, duration)
        MSK.Notification(title, message, typ, duration)
    end
    self.Notify = self.Notification

    self.accounts = {
        money = {name = 'money', money = self.PlayerData.money['cash']},
        black_money = {name = 'black_money', money = self.PlayerData.money['black_money']},
        bank = {name = 'bank', money = self.PlayerData.money['bank']},
    }

    self.GetAccount = function(account)
		return self.accounts[account:lower()]
    end

    self.Set = function(key, val)
        MSK.Bridge.SetPlayerData(key, val)
    end

    self.Get = function(val)
        return self.metadata[val]
    end

    self.HasItem = function(itemName, metadata)
        return MSK.HasItem(itemName, metadata)
    end

    self.IsDead = function()
        local isDead = IsPlayerDead(MSK.Player.clientId) or IsEntityDead(MSK.Player.ped)

        if GetResourceState("visn_are") ~= "missing" then
            local healthBuffer = exports.visn_are:GetHealthBuffer()
            isDead = healthBuffer.unconscious
        end
    
        if GetResourceState("osp_ambulance") ~= "missing" then
            local data = exports.osp_ambulance:GetAmbulanceData(MSK.Player.serverId)
            isDead = data.isDead or data.inLastStand
        end
    
        return isDead
    end

    MSK.Bridge.PlayerData = self
end