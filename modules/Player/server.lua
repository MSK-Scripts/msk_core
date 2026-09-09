local nativePlayer = Player -- save the FiveM native Player()
local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Player = {}

--------------------------------------------------------------------------------
-- Where the unified player object is built
--
-- This module runs in BOTH runtimes: eagerly inside msk_core, and compiled into
-- every consumer by import.lua. That is the whole point. msk_core hands out
-- flat functions and plain data through exports, because functions do not
-- survive the export boundary, and the object with methods is assembled here,
-- inside whichever resource asked for it.
--
-- In 3.x the object was built inside msk_core and exported. Everything on it
-- (AddItem, GetAccount, Notify, Set, Get) arrived as nil in the consumer, and
-- only the data half was ever usable.
--------------------------------------------------------------------------------
local call, getData, getDataList

if IS_CORE then
    call        = function(...) return MSK.Bridge.PlayerCall(...) end
    getData     = function(...) return MSK.Bridge.GetPlayerData(...) end
    getDataList = function(...) return MSK.Bridge.GetPlayersData(...) end
else
    call        = function(...) return exports.msk_core:PlayerCall(...) end
    getData     = function(...) return exports.msk_core:GetPlayerData(...) end
    getDataList = function(...) return exports.msk_core:GetPlayersData(...) end
end

---Turns unified player data into an object with methods.
---@param data table|nil
---@return table|nil
local function build(data)
    if not data then return nil end

    local id = data.source

    --- Re-reads every field from the framework. Call it after something else
    --- may have changed the player, the object itself is a snapshot.
    data.Refresh = function()
        local fresh = getData(id)
        if not fresh then return false end

        for key, value in pairs(fresh) do
            data[key] = value
        end

        return true
    end

    data.IsOnline = function()
        return getData(id) ~= nil
    end

    ----------------------------------------------------------------------------
    -- Job and gang
    ----------------------------------------------------------------------------
    data.SetJob = function(name, grade)
        return call(id, 'SetJob', name, grade)
    end

    data.SetGang = function(name, grade)
        return call(id, 'SetGang', name, grade)
    end

    data.SetDuty = function(onDuty)
        return call(id, 'SetDuty', onDuty)
    end

    --- Adds a job without removing the ones already held. Real multijob on
    --- Qbox; on ESX and QBCore, which store one job per player, it replaces the
    --- current job and returns true, so calling code does not need a branch.
    data.AddJob = function(name, grade)
        return call(id, 'AddJob', name, grade)
    end

    data.RemoveJob = function(name)
        return call(id, 'RemoveJob', name)
    end

    data.AddGang = function(name, grade)
        return call(id, 'AddGang', name, grade)
    end

    data.RemoveGang = function(name)
        return call(id, 'RemoveGang', name)
    end

    --- True when the player holds this job at all, primary or not.
    ---@param name string
    ---@param minGrade? integer
    data.HasJob = function(name, minGrade)
        local grade = data.jobs and data.jobs[name]
        if grade == nil then return false end

        return not minGrade or grade >= minGrade
    end

    data.HasGang = function(name, minGrade)
        local grade = data.gangs and data.gangs[name]
        if grade == nil then return false end

        return not minGrade or grade >= minGrade
    end

    data.IsBoss = function()
        return data.job and data.job.isBoss or false
    end

    data.IsOnDuty = function()
        return data.job and data.job.onDuty or false
    end

    ----------------------------------------------------------------------------
    -- Money
    --
    -- 'cash' and 'bank' exist on every framework. Anything else is passed
    -- through to the framework unchanged, so 'black' works on ESX and 'crypto'
    -- on QBCore and Qbox, and an account a framework does not have reads 0.
    ----------------------------------------------------------------------------
    data.GetMoney = function(account)
        return call(id, 'GetMoney', account)
    end

    data.AddMoney = function(account, amount, reason)
        return call(id, 'AddMoney', account, amount, reason)
    end

    data.RemoveMoney = function(account, amount, reason)
        return call(id, 'RemoveMoney', account, amount, reason)
    end

    data.SetMoney = function(account, amount, reason)
        return call(id, 'SetMoney', account, amount, reason)
    end

    ----------------------------------------------------------------------------
    -- Metadata
    ----------------------------------------------------------------------------
    data.GetMeta = function(key)
        return call(id, 'GetMeta', key)
    end

    data.SetMeta = function(key, value)
        return call(id, 'SetMeta', key, value)
    end

    ----------------------------------------------------------------------------
    -- Items
    --
    -- These reach the inventory adapter, not the framework. Which inventory
    -- runs is independent of which framework runs.
    --
    -- CanCarryItem and CanSwapItem may answer nil, meaning the running
    -- inventory cannot check that. nil is not false: treat it as "unknown" and
    -- decide yourself, do not read it as "no room".
    ----------------------------------------------------------------------------
    data.GetInventory = function()
        return call(id, 'GetInventory')
    end

    data.GetItem = function(name, metadata)
        return call(id, 'GetItem', name, metadata)
    end

    data.HasItem = function(name, count, metadata)
        return MSK.HasItem(id, name, count, metadata)
    end

    data.AddItem = function(name, count, metadata, slot)
        return call(id, 'AddItem', name, count, metadata, slot)
    end

    data.RemoveItem = function(name, count, metadata, slot)
        return call(id, 'RemoveItem', name, count, metadata, slot)
    end

    data.AddWeapon = function(name, count, metadata, slot)
        return call(id, 'AddWeapon', name, count, metadata, slot)
    end

    data.RemoveWeapon = function(name, count, metadata, slot)
        return call(id, 'RemoveWeapon', name, count, metadata, slot)
    end

    data.GetWeapon = function(name, metadata)
        return call(id, 'GetWeapon', name, metadata)
    end

    data.CanCarryItem = function(name, count, metadata)
        return call(id, 'CanCarryItem', name, count, metadata)
    end

    data.CanSwapItem = function(firstItem, firstCount, secondItem, secondCount)
        return call(id, 'CanSwapItem', firstItem, firstCount, secondItem, secondCount)
    end

    data.SetMaxWeight = function(maxWeight)
        return call(id, 'SetMaxWeight', maxWeight)
    end

    --- Empties the inventory. Answers nil when the running inventory cannot do
    --- it, which is not the same as false.
    data.ClearInventory = function()
        return call(id, 'ClearInventory')
    end

    ----------------------------------------------------------------------------
    -- Player actions
    ----------------------------------------------------------------------------
    data.Notify = function(...)
        return MSK.Notification(id, ...)
    end
    data.Notification = data.Notify

    data.Kick = function(reason)
        return call(id, 'Kick', reason)
    end

    data.Save = function()
        return call(id, 'Save')
    end

    data.GetCoords = function()
        return call(id, 'GetCoords')
    end

    data.SetCoords = function(coords)
        return call(id, 'SetCoords', coords)
    end

    data.GetPed = function()
        return GetPlayerPed(id)
    end

    return data
end
Player.Build = build

--------------------------------------------------------------------------------
-- Lookup
--
-- Get() takes whatever a caller has at hand: a server id, an identifier or
-- citizenid, or a table like { source = }, { identifier = }, { phone = },
-- { userId = }. In 3.x only the table form worked and MSK.GetPlayer(5) raised
-- "attempt to index a number value".
--------------------------------------------------------------------------------
---@param id number|string|table
---@return table|nil
function Player.Get(id)
    return build(getData(id))
end

---Unified data without the methods, for logging or sending over the wire.
---@param id number|string|table
---@return table|nil
function Player.GetData(id)
    return getData(id)
end

function Player.GetFromId(playerId)
    return build(getData(tonumber(playerId)))
end

function Player.GetFromIdentifier(identifier)
    return build(getData({ identifier = identifier }))
end

--- Same as GetFromIdentifier. On QBCore and Qbox the identifier IS the
--- citizenid, on ESX it is the ESX identifier.
function Player.GetByCitizenId(citizenid)
    return build(getData({ citizenid = citizenid }))
end

function Player.GetByPhone(phone)
    return build(getData({ phone = phone }))
end

--- Qbox only. Returns nil on every other framework.
function Player.GetByUserId(userId)
    return build(getData({ userId = userId }))
end

---@param key? 'job'|'gang'|'group'
---@param value? string
---@return table[] player objects
function Player.GetAll(key, value)
    local list = getDataList(key, value)

    for i = 1, #list do
        list[i] = build(list[i])
    end

    return list
end

--- Data only, no methods. Cheaper when you just want to count or filter.
function Player.GetAllData(key, value)
    return getDataList(key, value)
end

function Player.GetJob(id)
    local data = getData(id)
    return data and data.job or nil
end

function Player.GetGang(id)
    local data = getData(id)
    return data and data.gang or nil
end

function Player.GetJobs(id)
    local data = getData(id)
    return data and data.jobs or {}
end

function Player.GetIdentifier(id)
    local data = getData(id)
    return data and data.identifier or nil
end

function Player.GetServerId(id)
    local data = getData(id)
    return data and data.source or nil
end

if IS_CORE then
    --------------------------------------------------------------------------------
    -- Mirrored player table (core only)
    --
    -- MSK.Player[playerId] holds what the client reports about itself: ped,
    -- vehicle, coords, heading. Separate from the framework data above, which
    -- comes from the server side.
    --------------------------------------------------------------------------------
    setmetatable(Player, {
        __index = function(self, key)
            if type(key) == 'string' then
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

    --------------------------------------------------------------------------------
    -- Core-side names
    --
    -- Consumers reach these through aliases.lua, which points MSK.GetPlayer and
    -- friends at this module so the returned object keeps its methods.
    --------------------------------------------------------------------------------
    if MSK.Bridge.Framework.Type ~= 'STANDALONE' then
        MSK.GetPlayer = Player.Get
        MSK.GetPlayerFromId = Player.GetFromId
        MSK.GetPlayerFromIdentifier = Player.GetFromIdentifier
        MSK.GetPlayerByCitizenId = Player.GetByCitizenId
        MSK.GetPlayerByPhone = Player.GetByPhone
        MSK.GetPlayerByUserId = Player.GetByUserId
        MSK.GetPlayers = Player.GetAllData

        MSK.GetPlayerJobFromId = function(playerId)
            return Player.GetJob(tonumber(playerId))
        end

        MSK.GetPlayerJobFromIdentifier = function(identifier)
            return Player.GetJob({ identifier = identifier })
        end

        MSK.GetPlayerJobByCitizenId = function(citizenid)
            return Player.GetJob({ citizenid = citizenid })
        end

        exports('GetPlayerFromId', MSK.GetPlayerFromId)
        exports('GetPlayerFromIdentifier', MSK.GetPlayerFromIdentifier)
        exports('GetPlayerByCitizenId', MSK.GetPlayerByCitizenId)
        exports('GetPlayerByPhone', MSK.GetPlayerByPhone)
        exports('GetPlayerByUserId', MSK.GetPlayerByUserId)
        exports('GetPlayers', MSK.GetPlayers)
        exports('GetPlayerJobFromId', MSK.GetPlayerJobFromId)
        exports('GetPlayerJobFromIdentifier', MSK.GetPlayerJobFromIdentifier)
        exports('GetPlayerJobByCitizenId', MSK.GetPlayerJobByCitizenId)
    end
else
    -- Consumer: MSK.Player[id] is fetched from the core, one source, no
    -- duplicate handler.
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
