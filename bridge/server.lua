--------------------------------------------------------------------------------
-- Neutral bridge layer (server)
--
-- Sits on top of MSK.Bridge.Adapter and is the only place that knows what a
-- player looks like in msk_core. The adapters know their framework, this file
-- knows the shape. Nothing below this line branches on the framework.
--
-- What leaves this file are flat functions and plain data, never objects with
-- methods: msk_core hands its API to consumers through exports, and functions
-- do not survive the export boundary. The object with methods is built inside
-- the consumer by modules/Player, which import.lua compiles into it.
--------------------------------------------------------------------------------
if MSK.Bridge.Framework.Type == 'STANDALONE' then return end

local Adapter = MSK.Bridge.Adapter
local Inventory = MSK.Bridge.InventoryAdapter
local Events = MSK.Bridge.Framework.Events

--------------------------------------------------------------------------------
-- Resolving a player
--
-- Accepts everything a caller reasonably has at hand:
--   number            server id
--   numeric string    server id
--   string            identifier / citizenid
--   table             { source = }, { identifier = }, { citizenid = },
--                     { phone = }, { userId = }, { player = <raw> }
--------------------------------------------------------------------------------
local function resolveRaw(id)
    if id == nil then return nil end

    local kind = type(id)

    if kind == 'number' then
        return Adapter.getBySource(id)
    end

    if kind == 'string' then
        local asNumber = tonumber(id)
        if asNumber then
            return Adapter.getBySource(asNumber)
        end
        return Adapter.getByIdentifier(id)
    end

    if kind == 'table' then
        if id.player then return id.player end
        if id.source then return Adapter.getBySource(tonumber(id.source)) end
        if id.identifier then return Adapter.getByIdentifier(id.identifier) end
        if id.citizenid then return Adapter.getByIdentifier(id.citizenid) end
        if id.phone then return Adapter.getByPhone(id.phone) end
        if id.userId then return Adapter.getByUserId(id.userId) end
    end

    return nil
end
MSK.Bridge.ResolveRaw = resolveRaw

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------
---Unified player data. Plain data only, safe across the export boundary.
---@param id number|string|table
---@return table|nil
local function getPlayerData(id)
    local raw = resolveRaw(id)
    if not raw then return nil end

    return Adapter.read(raw)
end
MSK.Bridge.GetPlayerData = getPlayerData
exports('GetPlayerData', getPlayerData)

---@param key? 'job'|'gang'|'group' filter key, nil returns everyone
---@param value? string
---@return table[] list of unified player data
local function getPlayersData(key, value)
    local list = {}
    local raws

    if key == 'job' and value then
        raws = Adapter.getAllByJob(value)
    elseif key == 'gang' and value then
        raws = Adapter.getAllByGang(value)
    else
        raws = Adapter.getAll()
    end

    for i = 1, #raws do
        local data = Adapter.read(raws[i])

        if key == 'group' and value then
            -- Group membership is an ace question, not a framework one.
            if MSK.IsAceAllowed(data.source, value) then
                list[#list + 1] = data
            end
        else
            list[#list + 1] = data
        end
    end

    return list
end
MSK.Bridge.GetPlayersData = getPlayersData
exports('GetPlayersData', getPlayersData)

--------------------------------------------------------------------------------
-- Writing
--
-- One dispatch table instead of thirty near-identical exports. modules/Player
-- binds its methods to PlayerCall, and the named exports below are thin
-- wrappers for scripts that call msk_core directly instead of importing it.
--
-- Item functions deliberately go to the inventory adapter, not to the
-- framework: which inventory runs is independent of which framework runs.
--------------------------------------------------------------------------------
local methods = {
    SetJob = function(raw, name, grade)
        return Adapter.setJob(raw, name, grade)
    end,

    SetGang = function(raw, name, grade)
        return Adapter.setGang(raw, name, grade)
    end,

    SetDuty = function(raw, onDuty)
        return Adapter.setDuty(raw, onDuty)
    end,

    AddJob = function(raw, name, grade)
        return Adapter.addJob(raw, name, grade)
    end,

    RemoveJob = function(raw, name)
        return Adapter.removeJob(raw, name)
    end,

    AddGang = function(raw, name, grade)
        return Adapter.addGang and Adapter.addGang(raw, name, grade) or false
    end,

    RemoveGang = function(raw, name)
        return Adapter.removeGang and Adapter.removeGang(raw, name) or false
    end,

    GetMoney = function(raw, account)
        return Adapter.getMoney(raw, account or 'cash')
    end,

    AddMoney = function(raw, account, amount, reason)
        amount = tonumber(amount)
        if not amount or amount <= 0 then return false end

        return Adapter.addMoney(raw, account or 'cash', amount, reason)
    end,

    RemoveMoney = function(raw, account, amount, reason)
        amount = tonumber(amount)
        if not amount or amount <= 0 then return false end

        return Adapter.removeMoney(raw, account or 'cash', amount, reason)
    end,

    SetMoney = function(raw, account, amount, reason)
        amount = tonumber(amount)
        if not amount or amount < 0 then return false end

        return Adapter.setMoney(raw, account or 'cash', amount, reason)
    end,

    GetMeta = function(raw, key)
        return Adapter.getMeta(raw, key)
    end,

    SetMeta = function(raw, key, value)
        return Adapter.setMeta(raw, key, value)
    end,

    Kick = function(raw, reason)
        return Adapter.kick(raw, reason)
    end,

    Save = function(raw)
        return Adapter.save(raw)
    end,

    GetCoords = function(raw)
        return Adapter.getCoords(raw)
    end,

    SetCoords = function(raw, coords)
        return Adapter.setCoords(raw, coords)
    end,
}

-- Item methods take the server id, so they are resolved from the raw object
-- once and then handed to the inventory adapter.
local itemMethods = {
    GetInventory = 'getInventory',
    GetItem      = 'getItem',
    AddItem      = 'addItem',
    RemoveItem   = 'removeItem',
    AddWeapon    = 'addWeapon',
    RemoveWeapon = 'removeWeapon',
    GetWeapon    = 'getWeapon',
    CanCarryItem = 'canCarryItem',
    CanSwapItem  = 'canSwapItem',
    SetMaxWeight = 'setMaxWeight',
    ClearInventory = 'clear',
}

---Runs a player method by name. The single entry point modules/Player binds to.
---@param id number|string|table
---@param method string
---@return any
local function playerCall(id, method, ...)
    local inventoryMethod = itemMethods[method]

    if inventoryMethod then
        local fn = Inventory[inventoryMethod]

        if not fn then
            -- The running inventory cannot do this. nil is the honest answer,
            -- false would claim the inventory said no.
            return nil
        end

        local playerId = tonumber(id)

        if not playerId then
            local raw = resolveRaw(id)
            if not raw then return nil end

            local data = Adapter.read(raw)
            playerId = data.source
        end

        if not playerId then return nil end

        return fn(playerId, ...)
    end

    local fn = methods[method]
    if not fn then
        MSK.Logging('error', ('Unknown player method "%s".'):format(tostring(method)))
        return nil
    end

    local raw = resolveRaw(id)
    if not raw then return nil end

    return fn(raw, ...)
end
MSK.Bridge.PlayerCall = playerCall
exports('PlayerCall', playerCall)

-- Named exports for scripts that call msk_core directly instead of importing it.
exports('PlayerSetJob',      function(id, name, grade)          return playerCall(id, 'SetJob', name, grade) end)
exports('PlayerSetGang',     function(id, name, grade)          return playerCall(id, 'SetGang', name, grade) end)
exports('PlayerSetDuty',     function(id, onDuty)               return playerCall(id, 'SetDuty', onDuty) end)
exports('PlayerAddJob',      function(id, name, grade)          return playerCall(id, 'AddJob', name, grade) end)
exports('PlayerRemoveJob',   function(id, name)                 return playerCall(id, 'RemoveJob', name) end)
exports('PlayerGetMoney',    function(id, account)              return playerCall(id, 'GetMoney', account) end)
exports('PlayerAddMoney',    function(id, account, amount, why) return playerCall(id, 'AddMoney', account, amount, why) end)
exports('PlayerRemoveMoney', function(id, account, amount, why) return playerCall(id, 'RemoveMoney', account, amount, why) end)
exports('PlayerSetMoney',    function(id, account, amount, why) return playerCall(id, 'SetMoney', account, amount, why) end)
exports('PlayerGetMeta',     function(id, key)                  return playerCall(id, 'GetMeta', key) end)
exports('PlayerSetMeta',     function(id, key, value)           return playerCall(id, 'SetMeta', key, value) end)
exports('PlayerAddItem',     function(id, ...)                  return playerCall(id, 'AddItem', ...) end)
exports('PlayerRemoveItem',  function(id, ...)                  return playerCall(id, 'RemoveItem', ...) end)
exports('PlayerGetItem',     function(id, ...)                  return playerCall(id, 'GetItem', ...) end)

--------------------------------------------------------------------------------
-- Convenience lookups kept from 3.x, now on unified data
--------------------------------------------------------------------------------
MSK.GetPlayerServerId = function(id)
    local data = getPlayerData(id)
    return data and data.source or nil
end
MSK.GetServerId = MSK.GetPlayerServerId
exports('GetPlayerServerId', MSK.GetPlayerServerId)
exports('GetServerId', MSK.GetPlayerServerId)

MSK.GetPlayerIdentifier = function(id)
    local data = getPlayerData(id)
    if data then return data.identifier end

    -- Not logged in: fall back to the rockstar license, which exists as soon
    -- as the player is connected.
    local playerId = tonumber(id)
    if not playerId then return nil end

    local license = GetPlayerIdentifierByType(playerId --[[@as string]], 'license')
    return license and license:gsub('license:', '') or nil
end
MSK.GetIdentifier = MSK.GetPlayerIdentifier
exports('GetPlayerIdentifier', MSK.GetPlayerIdentifier)
exports('GetIdentifier', MSK.GetPlayerIdentifier)

---@return table|nil unified job table, not just the name
MSK.GetPlayerJob = function(id)
    local data = getPlayerData(id)
    return data and data.job or nil
end
exports('GetPlayerJob', MSK.GetPlayerJob)

---@return table|nil unified gang table
MSK.GetPlayerGang = function(id)
    local data = getPlayerData(id)
    return data and data.gang or nil
end
exports('GetPlayerGang', MSK.GetPlayerGang)

---Every job the player holds, as name -> grade. One entry on ESX and QBCore,
---the real multijob map on Qbox.
---@return table<string, integer>
MSK.GetPlayerJobs = function(id)
    local data = getPlayerData(id)
    return data and data.jobs or {}
end
exports('GetPlayerJobs', MSK.GetPlayerJobs)

--------------------------------------------------------------------------------
-- Job and gang definitions
--
-- Every framework keeps its list somewhere else: ESX behind GetJobs(), QBCore in
-- QBCore.Shared.Jobs, Qbox behind its own export. Scripts that only want to fill
-- a dropdown had to know all three, and usually covered two.
--------------------------------------------------------------------------------
---@return table<string, { name: string, label: string, grades: table? }>
MSK.GetJobs = function()
    return Adapter.getJobs and Adapter.getJobs() or {}
end
exports('GetJobs', MSK.GetJobs)

---@return table<string, { name: string, label: string, grades: table? }>
---Empty on ESX, which has no gangs.
MSK.GetGangs = function()
    return Adapter.getGangs and Adapter.getGangs() or {}
end
exports('GetGangs', MSK.GetGangs)

MSK.Register('msk_core:getJobs', function()
    return MSK.GetJobs()
end)

MSK.Register('msk_core:getGangs', function()
    return MSK.GetGangs()
end)

MSK.HasPlayerItem = function(id, itemName, count, metadata)
    local playerId = tonumber(id) or MSK.GetPlayerServerId(id)
    if not playerId then return false end

    return MSK.HasItem(playerId, itemName, count, metadata)
end
exports('HasPlayerItem', MSK.HasPlayerItem)

--------------------------------------------------------------------------------
-- Callback for the client
--
-- The client holds no framework adapter of its own, it receives what the server
-- sends. A client that starts (or restarts) after the player logged in has
-- missed the load event and asks once through here.
--
-- The same callback also serves the 'player' command parameter in
-- modules/Command, which asks for ANOTHER player. Both used to register a
-- callback under this name and the later one silently won.
--
-- About another player, a client gets identity and job only. The previous
-- version handed out the complete player table for any id a client cared to
-- ask about, which is every bank balance, every metadata field and the licence
-- on the server, available to anyone who could trigger a callback.
--------------------------------------------------------------------------------
local publicFields = {
    'source', 'identifier', 'name', 'firstName', 'lastName',
    'job', 'jobs', 'gang', 'gangs',
}

local function publicView(data)
    if not data then return nil end

    local view = {}

    for i = 1, #publicFields do
        local key = publicFields[i]
        view[key] = data[key]
    end

    return view
end

MSK.Register('msk_core:getPlayerData', function(playerId, targetId)
    targetId = tonumber(targetId)

    -- No target, or asking about yourself: everything.
    if not targetId or targetId == playerId then
        return MSK.LoadedPlayers[playerId] or getPlayerData(playerId)
    end

    return publicView(MSK.LoadedPlayers[targetId] or getPlayerData(targetId))
end)

--------------------------------------------------------------------------------
-- Load and unload
--
-- This is what 3.x was missing entirely: the bridge registered handlers for
-- msk_core:playerLoaded and friends, but nothing ever fired those events, so
-- MSK.LoadedPlayers stayed empty on every framework and every consumer waiting
-- for a load event waited forever.
--
-- The adapters name the real framework events, this file turns them into the
-- msk_core events that consumers listen to, with unified payloads.
--------------------------------------------------------------------------------
local function announceLoaded(playerId, data)
    MSK.LoadedPlayers[playerId] = data

    TriggerEvent(Events.playerLoaded, playerId, data)
    TriggerClientEvent(Events.playerLoaded, playerId, data)

    if Config.Debug then
        MSK.Logging('info', ('Player ^3%s^0 (^3%s^0) loaded'):format(playerId, tostring(data.identifier)))
    end
end

local handlers = {}

function handlers.loaded(playerId, raw)
    playerId = tonumber(playerId)
    if not playerId then return end

    raw = raw or Adapter.getBySource(playerId)
    if not raw then return end

    local data = Adapter.read(raw)
    local known = MSK.LoadedPlayers[playerId]

    -- Some frameworks fire more than one load event for the same character.
    -- Announcing twice would make consumers run their setup twice.
    if known and known.identifier == data.identifier then
        MSK.LoadedPlayers[playerId] = data
        return
    end

    announceLoaded(playerId, data)
end

function handlers.dropped(playerId)
    playerId = tonumber(playerId)
    if not playerId or not MSK.LoadedPlayers[playerId] then return end

    MSK.LoadedPlayers[playerId] = nil

    TriggerEvent(Events.playerLogout, playerId)
    TriggerClientEvent(Events.playerLogout, playerId)
end

function handlers.jobChanged(playerId, lastJobRaw)
    playerId = tonumber(playerId)
    if not playerId then return end

    local data = getPlayerData(playerId)
    if not data then return end

    local previous = MSK.LoadedPlayers[playerId]
    local lastJob = lastJobRaw or (previous and previous.job)

    MSK.LoadedPlayers[playerId] = data

    TriggerEvent(Events.setJob, playerId, data.job, lastJob)
    TriggerClientEvent(Events.setJob, playerId, data.job, lastJob)
end

function handlers.gangChanged(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    local data = getPlayerData(playerId)
    if not data then return end

    local previous = MSK.LoadedPlayers[playerId]
    local lastGang = previous and previous.gang

    MSK.LoadedPlayers[playerId] = data

    TriggerEvent(Events.setGang, playerId, data.gang, lastGang)
    TriggerClientEvent(Events.setGang, playerId, data.gang, lastGang)
end

function handlers.dutyChanged(playerId, onDuty)
    playerId = tonumber(playerId)
    if not playerId then return end

    local data = getPlayerData(playerId)
    if not data then return end

    MSK.LoadedPlayers[playerId] = data

    TriggerEvent(Events.setDuty, playerId, onDuty, data.job)
    TriggerClientEvent(Events.setDuty, playerId, onDuty, data.job)
end

Adapter.bindEvents(handlers)

-- A dropping player never reaches the framework logout event, so clean up here
-- as well. handlers.dropped is idempotent.
AddEventHandler('playerDropped', function()
    handlers.dropped(source)
end)

--------------------------------------------------------------------------------
-- Players already online when msk_core (re)starts
--
-- Without this every player would sit there unknown to msk_core until they
-- relog, which is exactly what a restart during live play must not cause.
--------------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateThread(function()
        -- Give the framework a moment to finish its own start-up before asking
        -- it for players.
        Wait(1000)

        local raws = Adapter.getAll()

        for i = 1, #raws do
            local data = Adapter.read(raws[i])

            if data.source then
                MSK.LoadedPlayers[data.source] = data
            end
        end

        if Config.Debug then
            MSK.Logging('info', ('Restored ^3%s^0 already connected players'):format(MSK.Table.Size(MSK.LoadedPlayers)))
        end
    end)
end)
