if MSK.Bridge.Framework.Type ~= 'QBCore' then return end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    if QBCore.Functions.GetPlayerData() then
        MSK.Bridge.isPlayerLoaded = true
    end
end)

GetPlayerData = function()
    if not MSK.Bridge.isPlayerLoaded then return end
    local player = QBCore.Functions.GetPlayerData()
    if not player then return end
    local job = player.PlayerData.job
    local self = {}
    
    self.identifier = player.PlayerData.citizenid
    self.firstName = player.PlayerData.charinfo.firstname
    self.lastName = player.PlayerData.charinfo.lastname
    self.name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    self.dob = player.PlayerData.charinfo.birthdate
    self.sex = player.PlayerData.charinfo.gender == 1 and 'male' or 'female'
    self.phone = player.PlayerData.charinfo.phone
    self.metadata = player.PlayerData.metadata
    self.inventory = player.PlayerData.items
    
    if MSK.Bridge.Inventory == 'ox_inventory' then
        self.inventory = exports.ox_inventory:GetPlayerItems()
        self.loadout = self.inventory
    end

    self.accounts = {
        money = {name = 'money', money = player.PlayerData.money['cash']},
        black_money = {name = 'black_money', money = player.PlayerData.money['black_money']},
        bank = {name = 'bank', money = player.PlayerData.money['bank']},
    }

    self.job = {
        name = job.name,
        label = job.label,
        grade = job.grade.level,
        grade_name = job.grade.name,
        grade_label = job.grade.name,
        grade_salary = job.payment,
        isBoss = job.isboss,
    }

    self.Notification = function(title, message, typ, duration)
        MSK.Notification(title, message, typ, duration)
    end
    self.Notify = self.Notification

    self.GetAccount = function(account)
        return self.accounts[account:lower()]
    end

    self.SetMeta = function(key, val)
        QBCore.Functions.SetMetaData(key, val)
    end

    self.GetMeta = function(val)
        return self.metadata[val]
    end

    self.IsDead = function()
        local isDead = IsPlayerDead(PlayerId()) or IsEntityDead(PlayerPedId())

        if GetResourceState("visn_are") ~= "missing" then
            local healthBuffer = exports.visn_are:GetHealthBuffer()
            isDead = healthBuffer.unconscious
        end
    
        if GetResourceState("osp_ambulance") ~= "missing" then
            local data = exports.osp_ambulance:GetAmbulanceData(GetPlayerServerId(PlayerId()))
            isDead = data.isDead or data.inLastStand
        end
    
        return isDead
    end

    return self
end
MSK.Bridge.Player = GetPlayerData