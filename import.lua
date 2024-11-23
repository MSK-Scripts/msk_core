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
    error(("Duplicate entires for '@%s/import.lua' detected! Please remove all duplicate entires in '%s/fxmanifest.lua'"):format(msk_core, resourceName))
end

if GetResourceState(msk_core) ~= 'started' then
    error('^1msk_core must be started before this resource.^0', 0)
end

local context = IsDuplicityVersion() and 'server' or 'client'

----------------------------------------------------------------
-- Export for MSK Library
----------------------------------------------------------------
MSK = exports.msk_core:GetLib()

MSK.name = resourceName

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

-- MSK.Timeout(ms, cb, data)
setmetatable(MSK.Timeout, {
    __call = function(self, ...)
        return self.Set(...)
    end
})

-- MSK.TextUI(key, text, color)
setmetatable(MSK.TextUI, {
    __call = function(self, ...)
        self.Show(...)
    end
})

if context == 'client' then
    -- MSK.Request(request, hasLoaded, assetType, asset, timeout, ...)
    setmetatable(MSK.Request, {
        __call = function(self, ...)
            return self.Streaming(...)
        end
    })
end

if context == 'server' then
    -- MSK.Check({auhtor = 'MSK-Scripts', name = 'msk_core', download? = 'url'})
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

            if tonumber(key) then
                return MSK.Trigger('msk_core:player', key)
            end
        end,
        __call = function(self, key, val, update)
            local value = rawget(self, key)
    
            if value == nil then
                if type(val) == 'function' then
                    value = func()
                else
                    value = val
                end
    
                rawset(self, key, value)

                if update then
                    TriggerEvent('msk_core:invokingUpdate', key, value)
                end
            end
    
            return value
        end
    })

    AddEventHandler('msk_core:onPlayer', function(key, value, oldValue)
        MSK.Player[key] = value
    end)
elseif context == 'server' then
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

----------------------------------------------------------------
-- Other stuff
----------------------------------------------------------------
if context == 'client' then
    RegisterNetEvent('msk_core:playerLoaded', function()
        MSK.Bridge.isPlayerLoaded = true

        -- esx_multicharacter support
        if MSK.Bridge.Framework.Type == 'ESX' and ESX then
            ESX.PlayerLoaded = true
            ESX.PlayerData = ESX.GetPlayerData()
        end
    end)

    RegisterNetEvent('msk_core:playerLogout', function()
        MSK.Bridge.isPlayerLoaded = false

        -- esx_multicharacter support
        if MSK.Bridge.Framework.Type == 'ESX' and ESX then
            ESX.PlayerLoaded = false
            ESX.PlayerData = {}
        end
    end)
end