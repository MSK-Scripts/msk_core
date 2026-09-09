--------------------------------------------------------------------------------
-- Neutral bridge layer (client)
--
-- There is deliberately no framework-specific client adapter any more. The
-- server already normalises player data and sends it out with every msk_core
-- event, so the client listens to those instead of reading ESX.PlayerData,
-- QBCore.PlayerData or QBX.PlayerData a second time.
--
-- Two things follow from that:
--   * One shape, one place. In 3.x the client rebuilt the player table on its
--     own and the QBCore branch read self.PlayerData.citizenid off a table that
--     is already the PlayerData, so it never produced anything.
--   * The client is not the authority. It receives what the server says a
--     player is, and it cannot write player data back. Anything that changes a
--     player runs on the server.
--------------------------------------------------------------------------------
if MSK.Bridge.Framework.Type == 'STANDALONE' then return end

local Events = MSK.Bridge.Framework.Events

local function setData(data)
    MSK.Bridge.PlayerData = data or {}
    MSK.Bridge.isPlayerLoaded = data ~= nil
end

RegisterNetEvent(Events.playerLoaded, function(data)
    setData(data)
end)

RegisterNetEvent(Events.playerLogout, function()
    setData(nil)
end)

RegisterNetEvent(Events.setJob, function(job)
    if not MSK.Bridge.isPlayerLoaded then return end

    MSK.Bridge.PlayerData.job = job
    MSK.Bridge.PlayerData.jobs = MSK.Bridge.PlayerData.jobs or {}

    if job then
        MSK.Bridge.PlayerData.jobs[job.name] = job.grade
    end
end)

RegisterNetEvent(Events.setGang, function(gang)
    if not MSK.Bridge.isPlayerLoaded then return end

    MSK.Bridge.PlayerData.gang = gang
end)

RegisterNetEvent(Events.setDuty, function(onDuty)
    if not MSK.Bridge.isPlayerLoaded or not MSK.Bridge.PlayerData.job then return end

    MSK.Bridge.PlayerData.job.onDuty = onDuty
end)

RegisterNetEvent(Events.setPlayerData, function(data)
    setData(data)
end)

--------------------------------------------------------------------------------
-- Current data
--------------------------------------------------------------------------------
---@return table|nil unified player data, nil while no character is loaded
MSK.GetPlayerData = function()
    return MSK.Bridge.isPlayerLoaded and MSK.Bridge.PlayerData or nil
end
exports('GetPlayerData', MSK.GetPlayerData)

---@return boolean
MSK.IsPlayerLoaded = function()
    return MSK.Bridge.isPlayerLoaded
end
exports('IsPlayerLoaded', MSK.IsPlayerLoaded)

---@return table|nil unified job table
MSK.GetPlayerJob = function()
    return MSK.Bridge.isPlayerLoaded and MSK.Bridge.PlayerData.job or nil
end
exports('GetPlayerJob', MSK.GetPlayerJob)

---@return table|nil unified gang table
MSK.GetPlayerGang = function()
    return MSK.Bridge.isPlayerLoaded and MSK.Bridge.PlayerData.gang or nil
end
exports('GetPlayerGang', MSK.GetPlayerGang)

---Every job the player holds, as name -> grade. One entry on ESX and QBCore,
---the real multijob map on Qbox.
---@return table<string, integer>
MSK.GetPlayerJobs = function()
    return MSK.Bridge.isPlayerLoaded and MSK.Bridge.PlayerData.jobs or {}
end
exports('GetPlayerJobs', MSK.GetPlayerJobs)

--------------------------------------------------------------------------------
-- Job and gang definitions
--
-- BLOCKING: a callback round trip, so call it from inside a thread. The list
-- lives on the server, which is also the only side that has it complete.
--------------------------------------------------------------------------------
---@return table<string, { name: string, label: string, grades: table? }>
MSK.GetJobs = function()
    return MSK.Trigger('msk_core:getJobs') or {}
end
exports('GetJobs', MSK.GetJobs)

---@return table<string, { name: string, label: string, grades: table? }>
MSK.GetGangs = function()
    return MSK.Trigger('msk_core:getGangs') or {}
end
exports('GetGangs', MSK.GetGangs)

--------------------------------------------------------------------------------
-- Death state
--
-- Used to sit on the client player object as PlayerData.IsDead(). It is not a
-- property of the player data at all, it is a question about the ped plus
-- whichever ambulance script is running, so it stands on its own now.
--------------------------------------------------------------------------------
---@return boolean
MSK.IsPlayerDead = function()
    local ped = PlayerPedId()
    local isDead = IsPlayerDead(PlayerId()) or IsEntityDead(ped) or IsPedFatallyInjured(ped)

    -- Before a character is loaded there is nothing for an ambulance script to
    -- know about, and asking anyway only produces empty answers.
    if not MSK.Bridge.isPlayerLoaded then
        return isDead
    end

    -- Every result is checked before it is indexed. These exports come from
    -- other resources, and a resource that is starting, reloading or erroring
    -- answers with nil. This function runs in the mirror thread every 100 ms,
    -- so an unchecked index here takes that thread down for good.
    if GetResourceState('visn_are') == 'started' then
        local ok, healthBuffer = pcall(function()
            return exports.visn_are:GetHealthBuffer()
        end)

        if ok and type(healthBuffer) == 'table' and healthBuffer.unconscious ~= nil then
            isDead = healthBuffer.unconscious
        end
    end

    if GetResourceState('osp_ambulance') == 'started' then
        local ok, data = pcall(function()
            return exports.osp_ambulance:GetAmbulanceData(GetPlayerServerId(PlayerId()))
        end)

        if ok and type(data) == 'table' then
            isDead = data.isDead or data.inLastStand or false
        end
    end

    return isDead
end
exports('IsPlayerDead', MSK.IsPlayerDead)

--------------------------------------------------------------------------------
-- Fetch on start
--
-- A player who is already logged in when this resource starts, or when the
-- client rejoins, has missed the load event. Asking once on start closes that
-- gap instead of leaving the client with empty data until the next relog.
--------------------------------------------------------------------------------
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateThread(function()
        while not NetworkIsSessionStarted() do
            Wait(200)
        end

        local data = MSK.Trigger('msk_core:getPlayerData')

        if data then
            setData(data)
            TriggerEvent(Events.playerLoaded, data)
        end
    end)
end)
