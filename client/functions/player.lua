local Player = {}

function Player:set(key, value)
    if self[key] ~= value then
        TriggerEvent('msk_core:onPlayer', key, value, self[key])
        self[key] = value

        return true
    end
end

function Player:remove(key)
    if self[key] then
        TriggerEvent('msk_core:onPlayerRemove', key, self[key])
        self[key] = nil

        return true
    end
end

Player:set('clientId', PlayerId())
Player:set('serverId', GetPlayerServerId(Player.clientId))
Player:set('playerId', Player.serverId)
Player:set('source', Player.serverId)

local Notify = function(title, message, typ, duration)
    MSK.Notification(title, message, typ, duration)
end
Player:set('Notify', Notify)

local GetPlayerDeath = function()
    local isDead = IsPlayerDead(Player.clientId) or IsEntityDead(Player.playerPed) or IsPedFatallyInjured(Player.playerPed)

    if GetResourceState("visn_are") == "started" then
        local healthBuffer = exports.visn_are:GetHealthBuffer()
        isDead = healthBuffer.unconscious
    end

    if GetResourceState("osp_ambulance") == "started" then
        local data = exports.osp_ambulance:GetAmbulanceData(Player.serverId)
        isDead = data.isDead or data.inLastStand
    end

    return isDead
end

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