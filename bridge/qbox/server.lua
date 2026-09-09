if MSK.Bridge.Framework.Type ~= 'Qbox' then return end

--------------------------------------------------------------------------------
-- Qbox server adapter
--
-- Qbox has no core object. Everything runs through exports.qbx_core, which
-- bridge/shared.lua exposes as QBX. Where a call needs the player, Qbox accepts
-- `Source | string` (server id or citizenid) as its identifier argument, so the
-- adapter passes PlayerData.source.
--
-- This branch exists because Qbox declares `provide 'qb-core'`. Running it
-- through the QBCore branch works, but flattens multijob: PlayerData.jobs is a
-- table<string, integer> that the qb compatibility layer cannot express.
--
-- API reference: https://docs.qbox.re/resources/qbx_core/exports/server
--------------------------------------------------------------------------------
local Adapter = MSK.Bridge.Adapter

-- Unified account name -> Qbox money type. Qbox has cash, bank and crypto.
-- There is no black money account, so 'black' resolves to nothing and the
-- unified money table simply has no `black` key on this framework.
local accountNames = {
    cash   = 'cash',
    money  = 'cash',
    bank   = 'bank',
    crypto = 'crypto',
}

local function accountName(name)
    return accountNames[name] or name
end

-- Qbox answers GetPermission with a table<string, boolean>, not with a name,
-- and marks it deprecated in favour of aces. The unified `group` field is a
-- string on every framework (ESX stores one directly), so the highest level
-- present wins. Handing the raw table through produced "table: 0x..." wherever
-- a consumer did tostring(player.group).
local groupRanking = { 'god', 'superadmin', 'admin', 'mod', 'moderator' }

local function highestGroup(permissions)
    if type(permissions) ~= 'table' then
        return type(permissions) == 'string' and permissions:lower() or 'user'
    end

    for i = 1, #groupRanking do
        if permissions[groupRanking[i]] then
            return groupRanking[i]
        end
    end

    return 'user'
end

--------------------------------------------------------------------------------
-- Events
--
-- Verified against qbx_core 1.24.0:
--   server/player.lua:1064  TriggerEvent('QBCore:Server:PlayerLoaded', self)
--   server/player.lua:747   TriggerEvent('QBCore:Server:OnPlayerUnload', source)
--   server/player.lua:266   TriggerEvent('QBCore:Server:OnJobUpdate', source, job)
--   server/player.lua:477   TriggerEvent('QBCore:Server:OnGangUpdate', source, gang)
--   server/player.lua:205   TriggerEvent('QBCore:Server:SetDuty', source, onduty)
--
-- Note that Qbox fires PlayerLoaded, not OnPlayerLoaded like qb-core does, and
-- hands over the player object instead of a source.
--------------------------------------------------------------------------------
function Adapter.bindEvents(on)
    AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
        local source = player and player.PlayerData and player.PlayerData.source
        if source then
            on.loaded(source, player)
        end
    end)

    AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
        on.dropped(source)
    end)

    AddEventHandler('QBCore:Server:OnJobUpdate', function(source)
        on.jobChanged(source)
    end)

    AddEventHandler('QBCore:Server:OnGangUpdate', function(source)
        on.gangChanged(source)
    end)

    AddEventHandler('QBCore:Server:SetDuty', function(source, onDuty)
        on.dutyChanged(source, onDuty)
    end)
end

--------------------------------------------------------------------------------
-- Lookup
--------------------------------------------------------------------------------
function Adapter.getBySource(playerId)
    playerId = tonumber(playerId)
    return playerId and QBX:GetPlayer(playerId) or nil
end

function Adapter.getByIdentifier(identifier)
    return identifier and QBX:GetPlayerByCitizenId(identifier) or nil
end

function Adapter.getByPhone(phone)
    return phone and QBX:GetPlayerByPhone(tostring(phone)) or nil
end

function Adapter.getByUserId(userId)
    return userId and QBX:GetPlayerByUserId(userId) or nil
end

function Adapter.getAll()
    local list = {}

    for _, player in pairs(QBX:GetQBPlayers() or {}) do
        list[#list + 1] = player
    end

    return list
end

function Adapter.getAllByJob(jobName)
    local list = {}

    for _, player in pairs(QBX:GetQBPlayers() or {}) do
        -- Multijob: match the whole job map, not just the primary job.
        if player.PlayerData.jobs and player.PlayerData.jobs[jobName] then
            list[#list + 1] = player
        end
    end

    return list
end

function Adapter.getAllByGang(gangName)
    local list = {}

    for _, player in pairs(QBX:GetQBPlayers() or {}) do
        if player.PlayerData.gangs and player.PlayerData.gangs[gangName] then
            list[#list + 1] = player
        end
    end

    return list
end

--------------------------------------------------------------------------------
-- Job and gang definitions (not players)
--------------------------------------------------------------------------------
function Adapter.getJobs()
    local jobs = {}

    for name, job in pairs(QBX:GetJobs() or {}) do
        jobs[name] = {
            name   = name,
            label  = type(job) == 'table' and job.label or name,
            grades = MSK.Bridge.NormaliseGrades(type(job) == 'table' and job.grades),
        }
    end

    return jobs
end

function Adapter.getGangs()
    local gangs = {}

    for name, gang in pairs(QBX:GetGangs() or {}) do
        gangs[name] = {
            name   = name,
            label  = type(gang) == 'table' and gang.label or name,
            grades = MSK.Bridge.NormaliseGrades(type(gang) == 'table' and gang.grades),
        }
    end

    return gangs
end

--------------------------------------------------------------------------------
-- Read
--------------------------------------------------------------------------------
local function readGroup(group)
    if not group or not group.name then return nil end

    return {
        name       = group.name,
        label      = group.label or group.name,
        grade      = group.grade and group.grade.level or 0,
        gradeName  = group.grade and group.grade.name,
        gradeLabel = group.grade and (group.grade.label or group.grade.name),
        salary     = group.payment or 0,
        isBoss     = group.isboss or false,
        onDuty     = group.onduty ~= false,
    }
end

function Adapter.read(player)
    local data = player.PlayerData
    local charinfo = data.charinfo or {}
    local money = data.money or {}

    return {
        source     = data.source,
        identifier = data.citizenid,
        license    = data.license,
        userId     = data.userId,
        name       = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):gsub('^%s+', ''),
        firstName  = charinfo.firstname,
        lastName   = charinfo.lastname,
        dob        = charinfo.birthdate,
        -- 0 = male. qbx_core/client/character.lua:323 builds it that way and
        -- :382 reads it back the same, so the mapping is not a guess.
        sex        = tonumber(charinfo.gender) == 1 and 'female' or 'male',
        phone      = charinfo.phone,
        group      = highestGroup(QBX:GetPermission(data.source)),
        job        = readGroup(data.job),
        jobs       = data.jobs or {},
        gang       = readGroup(data.gang),
        gangs      = data.gangs or {},
        money      = {
            cash   = money.cash,
            bank   = money.bank,
            crypto = money.crypto,
        },
        metadata   = data.metadata or {},
        position   = data.position,
    }
end

--------------------------------------------------------------------------------
-- Write
--------------------------------------------------------------------------------
function Adapter.setJob(player, name, grade)
    return player.Functions.SetJob(name, grade or 0) and true or false
end

function Adapter.setGang(player, name, grade)
    return player.Functions.SetGang(name, grade or 0) and true or false
end

function Adapter.setDuty(player, onDuty)
    player.Functions.SetJobDuty(onDuty and true or false)
    return true
end

-- Real multijob: the player keeps every job already held.
function Adapter.addJob(player, name, grade)
    return QBX:AddPlayerToJob(player.PlayerData.citizenid, name, grade or 0) and true or false
end

function Adapter.removeJob(player, name)
    return QBX:RemovePlayerFromJob(player.PlayerData.citizenid, name) and true or false
end

function Adapter.addGang(player, name, grade)
    return QBX:AddPlayerToGang(player.PlayerData.citizenid, name, grade or 0) and true or false
end

function Adapter.removeGang(player, name)
    return QBX:RemovePlayerFromGang(player.PlayerData.citizenid, name) and true or false
end

function Adapter.getMoney(player, account)
    return player.Functions.GetMoney(accountName(account)) or 0
end

function Adapter.addMoney(player, account, amount, reason)
    return player.Functions.AddMoney(accountName(account), amount, reason) and true or false
end

function Adapter.removeMoney(player, account, amount, reason)
    return player.Functions.RemoveMoney(accountName(account), amount, reason) and true or false
end

function Adapter.setMoney(player, account, amount, reason)
    return player.Functions.SetMoney(accountName(account), amount, reason) and true or false
end

function Adapter.getMeta(player, key)
    return player.Functions.GetMetaData(key)
end

function Adapter.setMeta(player, key, value)
    player.Functions.SetMetaData(key, value)
    return true
end

function Adapter.kick(player, reason)
    DropPlayer(player.PlayerData.source --[[@as string]], reason or '')
    return true
end

function Adapter.save(player)
    player.Functions.Save()
    return true
end

function Adapter.getCoords(player)
    return GetEntityCoords(GetPlayerPed(player.PlayerData.source))
end

function Adapter.setCoords(player, coords)
    SetEntityCoords(GetPlayerPed(player.PlayerData.source), coords.x, coords.y, coords.z, false, false, false, false)
    return true
end

-- Items are NOT handled here. Framework and inventory are two separate axes,
-- so everything item related lives in inventories/server/*.lua, including the
-- built-in inventory of this framework (inventories/server/default.lua).
