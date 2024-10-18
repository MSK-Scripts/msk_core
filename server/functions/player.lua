local Player = {}

local onPlayer = function(key, value, oldValue)
    local playerId = source

    if not Player[playerId] then
        Player[playerId] = {}
    end

    if Player[playerId][key] ~= value then
        Player[playerId][key] = value

        if key == 'vehicle' then
            Player[playerId][key] = NetworkGetEntityFromNetworkId(value)
            Player[playerId]['vehNetId'] = value
        end

        TriggerEvent('msk_core:OnPlayer', playerId, key, Player[playerId][key], oldValue)
    end
end
RegisterNetEvent('msk_core:onPlayer', onPlayer)

local onPlayerRemove = function(key, value)
    local playerId = source

    if not Player[playerId] then
        Player[playerId] = {}
    end

    if Player[playerId][key] then
        Player[playerId][key] = nil

        if key == 'vehicle' then
            Player[playerId]['vehNetId'] = nil
        end

        TriggerEvent('msk_core:OnPlayerRemove', playerId, key, value)
    end
end
RegisterNetEvent('msk_core:onPlayerRemove', onPlayerRemove)

MSK.Player = Player