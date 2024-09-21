if MSK.Bridge.Framework.Type ~= 'ESX' then return end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    if ESX.IsPlayerLoaded() then
        MSK.Bridge.isPlayerLoaded = true
    end
end)

GetPlayerData = function()
    if not MSK.Bridge.isPlayerLoaded then return end
    local player = ESX.GetPlayerData()
    if not player then return end
    local self = player

    self.dob = self.dateofbirth
    
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

    self.SetMeta = function(key, val)
        ESX.SetPlayerData(key, val)
    end

    self.GetMeta = function(val)
        return self[val]
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