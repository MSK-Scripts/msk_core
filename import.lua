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
-- Quick function access
----------------------------------------------------------------
-- MSK.Input(header, placeholder, field, cb)
setmetatable(MSK.Input, {
    __call = function(self, ...)
        self.Open(...)
    end
})

-- MSK.Numpad(pin, showPin, cb)
setmetatable(MSK.Numpad, {
    __call = function(self, ...)
        self.Open(...)
    end
})

-- MSK.Progress(data)
setmetatable(MSK.Progress, {
    __call = function(self, ...)
        self.Start(...)
    end
})

if context == 'client' then
    setmetatable(MSK.Request, {
        __call = function(_, request, hasLoaded, assetType, asset, timeout, ...)
            return MSK.Request.Streaming(request, hasLoaded, assetType, asset, timeout, ...)
        end
    })
end

if context == 'server' then
    -- MSK.Check(repo)
    setmetatable(MSK.Check, {
        __call = function(self, ...)
            self.Version(...)
        end
    })
end

----------------------------------------------------------------
-- MSK.Player
----------------------------------------------------------------
if context == 'client' then
    setmetatable(MSK.Player, {
        __index = function(self, key)
            if key == 'coords' then
                return GetEntityCoords(self.ped)
            elseif key == 'heading' then
                return GetEntityHeading(self.ped)
            elseif key == 'state' then
                return PlayerState(self.serverId).state
            end
        end
    })

    AddEventHandler('msk_core:onPlayer', function(key, value, oldValue)
        MSK.Player[key] = value
    end)
end

if context == 'server' then
    local metatable = {
        __index = function(self, key)
            if type(key) == "string" then
                return rawget(self, tonumber(key))
            end
        end
    }
    setmetatable(MSK.Player, metatable)

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

    AddEventHandler('msk_core:OnPlayer', function(playerId, key, value, oldValue)
        if not MSK.Player[playerId] then
            MSK.Player[playerId] = {}
            setmetatable(MSK.Player[playerId], playerMeta)
        end

        MSK.Player[playerId][key] = value
    end)

    for playerId, data in pairs(MSK.Player) do
        if not getmetatable(MSK.Player[playerId]) then
            setmetatable(MSK.Player[playerId], playerMeta)
        end
    end
end