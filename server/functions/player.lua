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
        elseif key == 'Notify' then
            Player[playerId][key] = function(...)
                MSK.Notification(playerId, ...)
            end
        elseif key == 'vehicle' then
            Player[playerId][key] = NetworkGetEntityFromNetworkId(value)
            Player[playerId]['vehNetId'] = value
        end

        TriggerEvent('msk_core:OnPlayer', playerId, key, Player[playerId][key], oldValue)
    end
end
RegisterNetEvent('msk_core:onPlayer', onPlayer)

MSK.Player = Player

-- For clientside MSK.Player[targetId] and MSK.Player.Get(targetId, key)
MSK.Register('msk_core:player', function(source, targetId, key)
    local targetId = tonumber(targetId)

    if DoesPlayerExist(targetId) then        
        return key and MSK.Player[targetId][key] or MSK.Player[targetId]
    end

    return false
end)