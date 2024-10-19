local PlayerState = Player
local Player = {}

local metatable = {
    __index = function(self, key)
        if type(key) == "string" then
            return rawget(self, tonumber(key))
        end
    end
}
setmetatable(Player, metatable)

local playerMeta = {
    __index = function(self, key)
        if key == 'coords' then
            return GetEntityCoords(self.ped)
        elseif key == 'heading' then
            return GetEntityHeading(self.ped)
        elseif key == 'state' then
            return PlayerState(self.serverId).state
        end
    end
}

local onPlayer = function(key, value, oldValue)
    local playerId = tonumber(source)

    if not Player[playerId] then
        Player[playerId] = {}
        setmetatable(Player[playerId], playerMeta)
    end

    if Player[playerId][key] ~= value then
        Player[playerId][key] = value

        if key == 'ped' or key == 'playerPed' then
            Player[playerId][key] = GetPlayerPed(playerId)
        elseif key == 'vehicle' then
            Player[playerId][key] = NetworkGetEntityFromNetworkId(value)
            Player[playerId]['vehNetId'] = value
        end

        TriggerEvent('msk_core:OnPlayer', playerId, key, Player[playerId][key], oldValue)
    end
end
RegisterNetEvent('msk_core:onPlayer', onPlayer)

local onPlayerRemove = function(key, value)
    local playerId = tonumber(source)
    if not Player[playerId] then return end

    Player[playerId][key] = nil

    if key == 'vehicle' then
        Player[playerId]['vehNetId'] = nil
    end

    TriggerEvent('msk_core:OnPlayerRemove', playerId, key, value)
end
RegisterNetEvent('msk_core:onPlayerRemove', onPlayerRemove)

MSK.Player = Player