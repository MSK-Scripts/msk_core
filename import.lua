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

local context = IsDuplicityVersion() and 'server' or 'client'

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
if context == 'client' then
    local Player = {
        clientId = MSK.Player.clientId,
        serverId = MSK.Player.serverId,
        playerId = MSK.Player.playerId,
        state = Player(MSK.Player.serverId).state,
        ped = MSK.Player.ped,
        playerPed = MSK.Player.ped,
        coords = MSK.Player.coords,
        heading = MSK.Player.heading,
        vehicle = MSK.Player.vehicle,
        seat = MSK.Player.seat,
        weapon = MSK.Player.weapon,
        isDead = MSK.Player.isDead,
        Notify = MSK.Player.Notify,
    }

    MSK.Player = Player

    AddEventHandler('msk_core:onPlayer', function(key, value, oldValue)
        MSK.Player[key] = value
    end)

    AddEventHandler('msk_core:onPlayerRemove', function(key, value)
        MSK.Player[key] = nil
    end)
end

if context == 'server' then
    AddEventHandler('msk_core:OnPlayer', function(playerId, key, value, oldValue)
        if not MSK.Player[playerId] then
            MSK.Player[playerId] = {}
        end

        MSK.Player[playerId][key] = value
    end)

    AddEventHandler('msk_core:OnPlayerRemove', function(playerId, key, value)
        if not MSK.Player[playerId] then return end
        MSK.Player[playerId][key] = nil
    end)
end