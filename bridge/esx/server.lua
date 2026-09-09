if MSK.Bridge.Framework.Type ~= 'ESX' then return end

--------------------------------------------------------------------------------
-- ESX server adapter
--
-- Reads from xPlayer and calls xPlayer functions. It never writes to xPlayer:
-- the unified player object is built by bridge/server.lua on top of what read()
-- returns, so ESX keeps its own job table, accounts and inventory untouched.
--
-- API reference: https://docs.esx-framework.org/en/esx_core/es_extended/server/xplayer
--------------------------------------------------------------------------------
local Adapter = MSK.Bridge.Adapter

-- Unified account name -> ESX account name. Anything not listed is passed
-- through unchanged, so xPlayer accounts added by other resources still work.
local accountNames = {
    cash        = 'money',
    money       = 'money',
    bank        = 'bank',
    black       = 'black_money',
    black_money = 'black_money',
}

local function accountName(name)
    return accountNames[name] or name
end

--------------------------------------------------------------------------------
-- Events
--
-- AddEventHandler, not RegisterNetEvent: these are triggered server-side by
-- es_extended. Registering them as net events would let any client fake a
-- player load.
--------------------------------------------------------------------------------
function Adapter.bindEvents(on)
    AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
        on.loaded(playerId, xPlayer)
    end)

    AddEventHandler('esx:playerDropped', function(playerId)
        on.dropped(playerId)
    end)

    AddEventHandler('esx:playerLogout', function(playerId)
        on.dropped(playerId)
    end)

    AddEventHandler('esx:setJob', function(playerId, job, lastJob)
        on.jobChanged(playerId, lastJob)
    end)
end

--------------------------------------------------------------------------------
-- Lookup
--------------------------------------------------------------------------------
function Adapter.getBySource(playerId)
    playerId = tonumber(playerId)
    return playerId and ESX.GetPlayerFromId(playerId) or nil
end

function Adapter.getByIdentifier(identifier)
    return identifier and ESX.GetPlayerFromIdentifier(identifier) or nil
end

-- ESX has no phone number on xPlayer. Resources that add one differ too much
-- to guess at, so this stays unsupported instead of returning a wrong player.
function Adapter.getByPhone()
    return nil
end

-- userId is a Qbox concept.
function Adapter.getByUserId()
    return nil
end

function Adapter.getAll()
    return ESX.GetExtendedPlayers()
end

function Adapter.getAllByJob(jobName)
    return ESX.GetExtendedPlayers('job', jobName)
end

-- ESX has no gangs.
function Adapter.getAllByGang()
    return {}
end

--------------------------------------------------------------------------------
-- Job and gang definitions (not players)
--------------------------------------------------------------------------------
function Adapter.getJobs()
    local jobs = {}

    for name, job in pairs(ESX.GetJobs() or {}) do
        jobs[name] = {
            name   = name,
            label  = type(job) == 'table' and job.label or name,
            grades = MSK.Bridge.NormaliseGrades(type(job) == 'table' and job.grades),
        }
    end

    return jobs
end

-- ESX has no gangs.
function Adapter.getGangs()
    return {}
end

--------------------------------------------------------------------------------
-- Read
--------------------------------------------------------------------------------
local function readSex(value)
    -- Documented as a number (0 = male, 1 = female), but characters created
    -- before ESX Legacy carry 'm' / 'f' straight from the database.
    if type(value) == 'string' then
        local lowered = value:lower()
        return (lowered == 'f' or lowered == 'female') and 'female' or 'male'
    end
    return tonumber(value) == 1 and 'female' or 'male'
end

local function readJob(job)
    if not job or not job.name then return nil end

    return {
        name       = job.name,
        label      = job.label or job.name,
        grade      = job.grade or 0,
        gradeName  = job.grade_name,
        gradeLabel = job.grade_label or job.grade_name,
        salary     = job.grade_salary or 0,
        -- ESX carries no boss flag. grade_name == 'boss' is the convention
        -- shared by esx_society and every job resource built on it.
        isBoss     = job.grade_name == 'boss',
        onDuty     = job.onDuty ~= false,
    }
end

function Adapter.read(xPlayer)
    local job = readJob(xPlayer.job)

    local money = {}
    for _, account in pairs(xPlayer.accounts or {}) do
        if account.name == 'money' then
            money.cash = account.money
        elseif account.name == 'black_money' then
            money.black = account.money
        else
            money[account.name] = account.money
        end
    end

    return {
        source     = xPlayer.source,
        identifier = xPlayer.identifier,
        license    = xPlayer.license,
        name       = xPlayer.getName and xPlayer.getName() or xPlayer.name,
        firstName  = xPlayer.firstName,
        lastName   = xPlayer.lastName,
        dob        = xPlayer.dateofbirth,
        sex        = readSex(xPlayer.sex),
        height     = xPlayer.height,
        phone      = nil,
        group      = xPlayer.group,
        job        = job,
        -- ESX knows exactly one job. The map is still filled so consumer code
        -- can read player.jobs on every framework without a branch.
        jobs       = job and { [job.name] = job.grade } or {},
        gang       = nil,
        gangs      = {},
        money      = money,
        metadata   = xPlayer.metadata or xPlayer.variables or {},
        position   = xPlayer.getCoords and xPlayer.getCoords(true) or nil,
    }
end

--------------------------------------------------------------------------------
-- Write
--------------------------------------------------------------------------------
function Adapter.setJob(xPlayer, name, grade)
    xPlayer.setJob(name, grade or 0)
    return true
end

-- ESX has no gangs.
function Adapter.setGang()
    return false
end

function Adapter.setDuty(xPlayer, onDuty)
    local job = xPlayer.job
    if not job then return false end

    xPlayer.setJob(job.name, job.grade, onDuty and true or false)
    return true
end

-- ESX holds one job per player, so adding one means replacing the current one.
function Adapter.addJob(xPlayer, name, grade)
    return Adapter.setJob(xPlayer, name, grade)
end

function Adapter.removeJob(xPlayer, name)
    if not xPlayer.job or xPlayer.job.name ~= name then return false end
    xPlayer.setJob('unemployed', 0)
    return true
end

function Adapter.getMoney(xPlayer, account)
    local acc = xPlayer.getAccount(accountName(account))
    return acc and acc.money or 0
end

function Adapter.addMoney(xPlayer, account, amount, reason)
    xPlayer.addAccountMoney(accountName(account), amount, reason)
    return true
end

function Adapter.removeMoney(xPlayer, account, amount, reason)
    local acc = xPlayer.getAccount(accountName(account))
    if not acc or (acc.money or 0) < amount then return false end

    xPlayer.removeAccountMoney(accountName(account), amount, reason)
    return true
end

function Adapter.setMoney(xPlayer, account, amount, reason)
    local name = accountName(account)
    local acc = xPlayer.getAccount(name)
    if not acc then return false end

    local diff = amount - (acc.money or 0)
    if diff > 0 then
        xPlayer.addAccountMoney(name, diff, reason)
    elseif diff < 0 then
        xPlayer.removeAccountMoney(name, -diff, reason)
    end
    return true
end

function Adapter.getMeta(xPlayer, key)
    return xPlayer.getMeta and xPlayer.getMeta(key) or nil
end

function Adapter.setMeta(xPlayer, key, value)
    if not xPlayer.setMeta then return false end
    xPlayer.setMeta(key, value)
    return true
end

function Adapter.kick(xPlayer, reason)
    xPlayer.kick(reason)
    return true
end

function Adapter.save(xPlayer)
    ESX.SavePlayer(xPlayer)
    return true
end

function Adapter.getCoords(xPlayer)
    return xPlayer.getCoords(true)
end

function Adapter.setCoords(xPlayer, coords)
    xPlayer.setCoords(coords)
    return true
end

-- Items are NOT handled here. Framework and inventory are two separate axes,
-- so everything item related lives in inventories/server/*.lua, including the
-- built-in inventory of this framework (inventories/server/default.lua).
