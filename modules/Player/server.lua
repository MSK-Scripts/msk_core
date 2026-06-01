local nativePlayer = Player -- save the FiveM native Player()
local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Player = {}

if IS_CORE then
    -- CORE: mirrored player table, events, callback, wrappers
    setmetatable(Player, {
        __index = function(self, key)
            if type(key) == "string" then
                return rawget(self, tonumber(key))
            end
        end
    })

    local playerMeta = {
        __index = function(self, key)
            if key == 'coords' then
                return GetEntityCoords(self.ped)
            elseif key == 'heading' then
                return GetEntityHeading(self.ped)
            elseif key == 'state' then
                return nativePlayer(self.serverId).state
            end
        end
    }

    local function onPlayer(key, value, oldValue)
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

    -- Callback for the client-side MSK.Player[targetId] / MSK.Player.Get(targetId, key)
    MSK.Register('msk_core:player', function(source, targetId, key)
        targetId = tonumber(targetId)

        if DoesPlayerExist(targetId) then
            return key and Player[targetId][key] or Player[targetId]
        end

        return false
    end)

    -- Fetches MSK.Player[id] through this.
    exports('GetMirroredPlayer', function(id)
        return Player[tonumber(id)]
    end)

    -- Only meaningful with a framework -> only register then.
    if MSK.Bridge.Framework.Type ~= 'STANDALONE' then
        MSK.GetPlayerFromId = function(playerId)
            return MSK.GetPlayer({source = playerId})
        end
        exports('GetPlayerFromId', MSK.GetPlayerFromId)

        MSK.GetPlayerFromIdentifier = function(identifier)
            return MSK.GetPlayer({identifier = identifier})
        end
        exports('GetPlayerFromIdentifier', MSK.GetPlayerFromIdentifier)

        MSK.GetPlayerByCitizenId = function(citizenid)
            return MSK.GetPlayer({citizenid = citizenid})
        end
        exports('GetPlayerByCitizenId', MSK.GetPlayerByCitizenId)

        MSK.GetPlayerJobFromId = function(playerId)
            return MSK.GetPlayerJob({source = playerId})
        end
        exports('GetPlayerJobFromId', MSK.GetPlayerJobFromId)

        MSK.GetPlayerJobFromIdentifier = function(identifier)
            return MSK.GetPlayerJob({identifier = identifier})
        end
        exports('GetPlayerJobFromIdentifier', MSK.GetPlayerJobFromIdentifier)

        MSK.GetPlayerJobByCitizenId = function(citizenid)
            return MSK.GetPlayerJob({citizenid = citizenid})
        end
        exports('GetPlayerJobByCitizenId', MSK.GetPlayerJobByCitizenId)

        MSK.GetPlayers = function(key, val)
            local Players

            if MSK.Bridge.Framework.Type == 'ESX' then
                Players = ESX.GetExtendedPlayers(key, val)
            elseif MSK.Bridge.Framework.Type == 'QBCore' then
                if not key then
                    Players = QBCore.Functions.GetQBPlayers()
                else
                    local qbPlayers = {}

                    for _, qbPlayer in pairs(QBCore.Functions.GetQBPlayers()) do
                        if key == 'job' then
                            if qbPlayer.PlayerData.job.name == val then
                                qbPlayers[#qbPlayers + 1] = qbPlayer
                            end
                        elseif key == 'gang' then
                            if qbPlayer.PlayerData.gang.name == val then
                                qbPlayers[#qbPlayers + 1] = qbPlayer
                            end
                        elseif key == 'group' then
                            if MSK.IsAceAllowed(qbPlayer.PlayerData.source, val) then
                                qbPlayers[#qbPlayers + 1] = qbPlayer
                            end
                        end
                    end

                    Players = qbPlayers
                end
            elseif MSK.Bridge.Framework.Type == 'OXCore' then
                Players = key and Ox.GetPlayers({[key] = val}) or Ox.GetPlayers()
            end

            return Players
        end
        exports('GetPlayers', MSK.GetPlayers)
    end
else
    -- fetch MSK.Player[id] from the core (one source, no duplicate handler)
    setmetatable(Player, {
        __index = function(self, key)
            local id = tonumber(key)
            if id then
                return exports.msk_core:GetMirroredPlayer(id)
            end
        end
    })
end

return Player
