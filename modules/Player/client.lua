local nativePlayer = Player -- save the FiveM native Player() (shadowed below by local Player)
local IS_CORE = GetCurrentResourceName() == 'msk_core'

-- Seat of a ped (inline, so Player does NOT depend on the Vehicle module)
local function seatOf(ped, vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    for i = -1, 16 do
        if GetPedInVehicleSeat(vehicle, i) == ped then return i end
    end
    return false
end

local Player = {}

---Gets a value of another player from the server (callback).
function Player.Get(playerId, key)
    return MSK.Trigger('msk_core:player', playerId, key)
end

if IS_CORE then
    ----------------------------------------------------------------------------
    -- CORE: thread + events (exactly once)
    ----------------------------------------------------------------------------
    function Player:set(key, value)
        if self[key] ~= value then
            TriggerEvent('msk_core:onPlayer', key, value, self[key])
            TriggerServerEvent('msk_core:onPlayer', key, key == 'vehicle' and DoesEntityExist(value) and NetworkGetNetworkIdFromEntity(value) or value, self[key])
            self[key] = value
            return true
        end
    end

    setmetatable(Player, {
        __index = function(self, key)
            if key == 'coords' then
                return GetEntityCoords(self.ped)
            elseif key == 'heading' then
                return GetEntityHeading(self.ped)
            elseif key == 'state' then
                return nativePlayer(self.serverId).state
            end
            if tonumber(key) then
                return MSK.Trigger('msk_core:player', key)
            end
        end,
        __call = function(self, key, val, update)
            local value = rawget(self, key)
            if value == nil then
                value = type(val) == 'function' and val() or val -- Fix BUG-013: was `func()` (undefined)
                rawset(self, key, value)
                if update then
                    TriggerEvent('msk_core:invokingUpdate', key, value)
                end
            end
            return value
        end
    })

    Player:set('clientId', PlayerId())
    Player:set('serverId', GetPlayerServerId(Player.clientId))
    Player:set('playerId', Player.serverId)
    Player:set('Notify', function(title, message, typ, duration)
        MSK.Notification(title, message, typ, duration)
    end)

    local function getPlayerDeath()
        local isDead = IsPlayerDead(Player.clientId) or IsEntityDead(Player.ped) or IsPedFatallyInjured(Player.ped)

        if MSK.Bridge.isPlayerLoaded then
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
                    Player:set('seat', seatOf(Player.ped, vehicle))
                end
            else
                Player:set('vehicle', false)
                Player:set('seat', false)
            end

            local hasWeapon, currentWeapon = GetCurrentPedWeapon(Player.ped, true)
            Player:set('weapon', hasWeapon and currentWeapon or false)
            Player:set('isDead', getPlayerDeath())

            Wait(100)
        end
    end)

    -- Own/custom keys (also from consumers via MSK.Player(key, val, true) -> invokingUpdate)
    local standardKeys = {
        clientId = true, serverId = true, playerId = true, Notify = true,
        coords = true, heading = true, state = true,
        ped = true, playerPed = true, vehicle = true, seat = true, weapon = true, isDead = true,
    }
    AddEventHandler('msk_core:invokingUpdate', function(key, value)
        if standardKeys[key] then return end
        Player:set(key, value)
    end)
else
    -- read-only view, all fields local from natives (no thread/event)
    setmetatable(Player, {
        __index = function(self, key)
            if key == 'clientId' then
                return PlayerId()
            elseif key == 'serverId' or key == 'playerId' then
                return GetPlayerServerId(PlayerId())
            elseif key == 'ped' or key == 'playerPed' then
                return PlayerPedId()
            elseif key == 'coords' then
                return GetEntityCoords(PlayerPedId())
            elseif key == 'heading' then
                return GetEntityHeading(PlayerPedId())
            elseif key == 'state' then
                return nativePlayer(GetPlayerServerId(PlayerId())).state
            elseif key == 'vehicle' then
                local v = GetVehiclePedIsIn(PlayerPedId(), false)
                return (v > 0 and DoesEntityExist(v)) and v or false
            elseif key == 'seat' then
                return seatOf(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false))
            elseif key == 'weapon' then
                local hasWeapon, currentWeapon = GetCurrentPedWeapon(PlayerPedId(), true)
                return hasWeapon and currentWeapon or false
            elseif key == 'isDead' then
                return IsPlayerDead(PlayerId()) or IsEntityDead(PlayerPedId())
            elseif key == 'Notify' then
                return function(title, message, typ, duration)
                    MSK.Notification(title, message, typ, duration)
                end
            end
            if tonumber(key) then
                return MSK.Trigger('msk_core:player', key)
            end
        end,
        __call = function(self, key, val, update)
            local value = rawget(self, key)
            if value == nil then
                value = type(val) == 'function' and val() or val
                rawset(self, key, value)
                if update then
                    -- Propagates custom keys to the core (whose invokingUpdate handler -> server mirror)
                    TriggerEvent('msk_core:invokingUpdate', key, value)
                end
            end
            return value
        end
    })
end

return Player
