local Player = {}

Player.clientId = PlayerId()
Player.serverId = GetPlayerServerId(Player.clientId)
Player.playerId = Player.serverId

MSK.Player = Player

function Player:set(key, value)
    if self[key] ~= value then
        TriggerEvent('msk_core:onPlayer', key, value, self[key])
        self[key] = value

        return true
    end
end

CreateThread(function()
	while true do
        Player:set('clientId', PlayerId())
        Player:set('serverId', GetPlayerServerId(Player.clientId))
        Player:set('playerId', Player.serverId)

        local playerPed = PlayerPedId()
        Player:set('playerPed', playerPed)

        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle > 0 and DoesEntityExist(vehicle) then
            Player:set('vehicle', vehicle)

            if not Player.seat or GetPedInVehicleSeat(vehicle, Player.seat) ~= playerPed then
                Player:set('seat', MSK.GetPedVehicleSeat(playerPed, vehicle))
                TriggerEvent('msk_core:onSeatChange', Player.vehicle, Player.seat)
            end
        else
            Player:set('vehicle', false)
            Player:set('seat', false)
        end

        local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, true)
        Player:set('weapon', hasWeapon and currentWeapon or false)

        Wait(100)
    end
end)