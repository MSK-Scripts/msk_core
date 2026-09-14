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

---Calls `cb(playerId, value, oldValue)` whenever `key` changes in the mirror of
---any player, e.g. vehicle, seat, weapon, isDead or a custom key. Returns the
---event handler, pass it to RemoveEventHandler to stop listening.
---  MSK.OnPlayer('isDead', function(playerId, isDead) ... end)
---@param key string
---@param cb fun(playerId: number, value: any, oldValue: any)
---@return table eventData
function Player.OnChange(key, cb)
    assert(type(key) == 'string', 'Parameter "key" has to be a string on function MSK.OnPlayer')
    assert(cb ~= nil, 'Parameter "cb" is nil on function MSK.OnPlayer')

    return AddEventHandler('msk_core:OnPlayer', function(playerId, changedKey, value, oldValue)
        if changedKey == key then
            cb(playerId, value, oldValue)
        end
    end)
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

    --------------------------------------------------------------------------------
    -- What a client may report about itself
    --
    -- The client used to be trusted with any key and any value. Sending `coords`
    -- stored a plain field that hid the computed getter, so the server handed out
    -- whatever position the client made up. isDead, vehicle and serverId could be
    -- faked the same way, and unlimited custom keys meant unlimited memory.
    --
    -- Known keys are checked or taken from the server's own view. Custom keys
    -- (MSK.Player(key, value, true)) stay possible, within limits.
    --------------------------------------------------------------------------------
    local COMPUTED = { coords = true, heading = true, state = true, vehNetId = true }
    local MAX_CUSTOM_KEYS = 64
    local MAX_KEY_LENGTH = 64
    local MAX_STRING_LENGTH = 1024
    local MAX_TABLE_SIZE = 4096
    local VEHICLE_RANGE = 15.0

    local function isSeat(value)
        return math.type(value) == 'integer' and value >= -1 and value <= 16
    end

    local KNOWN = {
        clientId = function(_, value)
            return math.type(value) == 'integer', value
        end,
        serverId = function(playerId) return true, playerId end,
        playerId = function(playerId) return true, playerId end,
        ped = function(playerId) return true, GetPlayerPed(playerId) end,
        playerPed = function(playerId) return true, GetPlayerPed(playerId) end,
        Notify = function(playerId)
            return true, function(...)
                MSK.Notification(playerId, ...)
            end
        end,
        seat = function(_, value)
            return value == false or isSeat(value), value
        end,
        weapon = function(_, value)
            return value == false or math.type(value) == 'integer', value
        end,
        isDead = function(_, value)
            return type(value) == 'boolean', value
        end,
    }

    local function acceptVehicle(playerId, netId)
        if netId == false or netId == nil then return false, nil end
        if math.type(netId) ~= 'integer' then return nil end

        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if vehicle == 0 or not DoesEntityExist(vehicle) then return false, nil end

        -- A vehicle far away from the player is not the one they sit in.
        local ped = GetPlayerPed(playerId)
        if ped ~= 0 and #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > VEHICLE_RANGE then
            return nil
        end

        return vehicle, netId
    end

    local function acceptCustom(data, key, value)
        if #key > MAX_KEY_LENGTH then return false end

        local kind = type(value)

        if kind == 'string' then
            if #value > MAX_STRING_LENGTH then return false end
        elseif kind == 'table' then
            local ok, encoded = pcall(json.encode, value)
            if not ok or #encoded > MAX_TABLE_SIZE then return false end
        elseif kind ~= 'number' and kind ~= 'boolean' and value ~= nil then
            return false
        end

        if rawget(data, key) == nil and value ~= nil then
            local count = 0
            for _ in pairs(data) do count = count + 1 end
            if count >= MAX_CUSTOM_KEYS + 16 then return false end
        end

        return true
    end

    local function onPlayer(key, value)
        local playerId = tonumber(source)
        if not playerId or type(key) ~= 'string' or COMPUTED[key] then return end

        local data = Player[playerId]

        if not data then
            data = setmetatable({}, playerMeta)
            Player[playerId] = data
        end

        local oldValue = rawget(data, key)
        local stored

        if key == 'vehicle' then
            local vehicle, netId = acceptVehicle(playerId, value)
            if vehicle == nil then return end

            stored = vehicle
            data.vehNetId = netId
        elseif KNOWN[key] then
            local ok, checked = KNOWN[key](playerId, value)
            if not ok then return end

            stored = checked
        else
            if not acceptCustom(data, key, value) then return end

            stored = value
        end

        -- A new function is never equal to the old one, so Notify is only set once.
        if key == 'Notify' and oldValue ~= nil then return end
        if oldValue == stored then return end

        data[key] = stored
        TriggerEvent('msk_core:OnPlayer', playerId, key, stored, oldValue)
    end
    RegisterNetEvent('msk_core:onPlayer', onPlayer)

    -- The mirror is cleared on disconnect. It used to stay forever, and a reused
    -- server id started out with the values of whoever had it before.
    AddEventHandler('playerDropped', function()
        local playerId = tonumber(source)
        if playerId then Player[playerId] = nil end
    end)

    -- Callback for the client-side MSK.Player[targetId] / MSK.Player.Get(targetId, key)
    MSK.Register('msk_core:player', function(source, targetId, key)
        targetId = tonumber(targetId)

        if not targetId or not DoesPlayerExist(targetId) then
            return false
        end

        local data = Player[targetId]

        -- Written out on purpose: `key and data[key] or data` returned the whole
        -- table for every value that is false (vehicle, isDead), and indexed nil
        -- for a player who had not reported anything yet.
        if key ~= nil then
            if not data then return nil end

            local value = data[key]
            if type(value) == 'function' then return nil end

            return value
        end

        local copy = {}

        if data then
            for field, value in pairs(data) do
                if type(value) ~= 'function' then
                    copy[field] = value
                end
            end
        end

        return copy
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
