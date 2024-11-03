local PlayerState = Player
local Player = {}

Player.Get = function(playerId, key)
    return MSK.Trigger('msk_core:player', playerId, key)
end

function Player:set(key, value)
    if self[key] ~= value then
        TriggerEvent('msk_core:onPlayer', key, value, self[key])
        TriggerServerEvent('msk_core:onPlayer', key, key == 'vehicle' and DoesEntityExist(value) and NetworkGetNetworkIdFromEntity(value) or value, self[key])
        self[key] = value

        return true
    end
end

Player:set('clientId', PlayerId())
Player:set('serverId', GetPlayerServerId(Player.clientId))
Player:set('playerId', Player.serverId)

local Notify = function(title, message, typ, duration)
    MSK.Notification(title, message, typ, duration)
end
Player:set('Notify', Notify)

local GetPlayerDeath = function()
    local isDead = IsPlayerDead(Player.clientId) or IsEntityDead(Player.ped) or IsPedFatallyInjured(Player.ped)

    if GetResourceState("visn_are") == "started" then
        local healthBuffer = MSK.Call(function() 
            return exports.visn_are:GetHealthBuffer()
        end)

        isDead = healthBuffer.unconscious
    end

    if GetResourceState("osp_ambulance") == "started" then
        local data = MSK.Call(function() 
            return exports.osp_ambulance:GetAmbulanceData(Player.serverId)
        end)

        isDead = data.isDead or data.inLastStand
    end

    return isDead
end

setmetatable(Player, {
    __index = function(self, key)
        if key == 'coords' then
            return GetEntityCoords(self.ped)
        elseif key == 'heading' then
            return GetEntityHeading(self.ped)
        elseif key == 'state' then
            return PlayerState(self.serverId).state
        end

        if tonumber(key) then
            return MSK.Trigger('msk_core:player', key)
        end
    end
})

CreateThread(function()
	while true do
        Player:set('ped', PlayerPedId())
        Player:set('playerPed', Player.ped)
        
        local vehicle = GetVehiclePedIsIn(Player.ped, false)

        if vehicle > 0 and DoesEntityExist(vehicle) then
            Player:set('vehicle', vehicle)

            if not Player.seat or GetPedInVehicleSeat(vehicle, Player.seat) ~= Player.ped then
                Player:set('seat', MSK.GetPedVehicleSeat(Player.ped, vehicle))
            end
        else
            Player:set('vehicle', false)
            Player:set('seat', false)
        end

        local hasWeapon, currentWeapon = GetCurrentPedWeapon(Player.ped, true)
        Player:set('weapon', hasWeapon and currentWeapon or false)

        Player:set('isDead', GetPlayerDeath())

        Wait(100)
    end
end)

MSK.Player = Player