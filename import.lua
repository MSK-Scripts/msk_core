----------------------------------------------------------------
-- General Stuff
----------------------------------------------------------------
if not _VERSION:find('5.4') then
    error("Enable Lua 5.4 in the fxmanifest.lua! (lua54 'yes')", 2)
end

local resourceName = GetCurrentResourceName()
local msk_core = 'msk_core'

if resourceName == msk_core then return end

if MSK and MSK.name == msk_core then
    error(("Duplicate entires for '@%s/fxmanifest.lua' detected! Please remove all duplicate entires in '%s/fxmanifest.lua'"):format(msk_core, resourceName))
end

if GetResourceState(msk_core) ~= 'started' then
    error('^1msk_core must be started before this resource.^0', 0)
end

----------------------------------------------------------------
-- Export for MSK Library
----------------------------------------------------------------
MSK = exports.msk_core:GetLib()

----------------------------------------------------------------
-- Support for old Scripts
----------------------------------------------------------------
-- MSK.Input(header, placeholder, field, cb)
setmetatable(MSK.Input, {
    __call = function(self, header, placeholder, field, cb)
        self.Open(header, placeholder, field, cb)
    end
})

-- MSK.Numpad(pin, showPin, cb)
setmetatable(MSK.Numpad, {
    __call = function(self, pin, showPin, cb)
        self.Open(pin, showPin, cb)
    end
})

-- MSK.Progress(data)
setmetatable(MSK.Progress, {
    __call = function(self, data, text, color)
        self.Start(data, text, color)
    end
})

----------------------------------------------------------------
-- MSK.Player
----------------------------------------------------------------
if not IsDuplicityVersion() then
    MSK.Player = {}

    MSK.Player.clientId = PlayerId()
    MSK.Player.serverId = GetPlayerServerId(MSK.Player.clientId)
    MSK.Player.playerId = MSK.Player.serverId

    CreateThread(function()
        local playerPed = PlayerPedId()
        MSK.Player.playerPed = playerPed

        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle > 0 and DoesEntityExist(vehicle) then
            MSK.Player.vehicle = vehicle

            if not MSK.Player.seat or GetPedInVehicleSeat(vehicle, MSK.Player.seat) ~= playerPed then
                MSK.Player.seat = MSK.GetPedVehicleSeat(playerPed, vehicle)
            end
        else
            MSK.Player.vehicle = false
            MSK.Player.seat = false
        end

        local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, true)
        MSK.Player.weapon = hasWeapon and currentWeapon or false
    end)

    AddEventHandler('msk_core:onPlayer', function(key, value, oldValue)
        MSK.Player[key] = value
    end)
end