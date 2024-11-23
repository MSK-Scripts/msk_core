if MSK.Bridge.Framework.Type ~= 'ESX' then return end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    if ESX.IsPlayerLoaded() then
        MSK.Bridge.isPlayerLoaded = true
        ESX.PlayerLoaded = true

        local playerData = ESX.GetPlayerData()
        ESX.PlayerData = playerData
        MSK.Bridge.PlayerData = playerData

        SetPlayerData()
    end
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setPlayerData, function(key, value)
    local invoke = GetInvokingResource()
    if not invoke or invoke ~= 'msk_core' then return end

    MSK.Bridge.PlayerData[key] = value

    SetPlayerData()
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLoaded, function(xPlayer, isNew, skin)
    ESX.PlayerData = xPlayer
 	ESX.PlayerLoaded = true

    MSK.Bridge.isPlayerLoaded = true
    MSK.Bridge.PlayerData = xPlayer
    
    SetPlayerData()
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLogout, function()
    ESX.PlayerLoaded = false
	ESX.PlayerData = {}

    MSK.Bridge.isPlayerLoaded = false
    MSK.Bridge.PlayerData = {}
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setJob, function(newJob, lastJob)
    MSK.Bridge.PlayerData.job = newJob
    SetPlayerData()
end)

MSK.Bridge.SetPlayerData = function(key, value)
    MSK.Bridge.PlayerData[key] = value
    ESX.SetPlayerData(key, value)
    SetPlayerData()
end

SetPlayerData = function()
    local self = MSK.Bridge.PlayerData

    self.dob = self.dateofbirth

    local job = self.job

    if job then
        self.job = {
            name = job.name,
            label = job.name,
            grade = job.grade,
            grade_name = job.grade_name,
            grade_label = job.grade_label,
            grade_salary = job.grade_salary,
            isBoss = job.grade_name == 'boss'
        }
    end

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

    self.GetAccount = function(account)
        for i = 1, #self.accounts do
			if self.accounts[i].name == account then
				return self.accounts[i]
			end
		end
		return nil
    end

    self.Set = function(key, val)
        MSK.Bridge.SetPlayerData(key, val)
    end

    self.Get = function(val)
        return self[val]
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