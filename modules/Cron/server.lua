local IS_CORE = GetCurrentResourceName() == 'msk_core'
MSK.Cron = {}

-- The two tick loops and the msk_core:createCron listener are core-owned
-- singletons: they must run EXACTLY ONCE, inside msk_core. A consumer that
-- eager-loads this module would otherwise start its own tick loops and a second
-- createCron listener, so a cron job could execute twice. Consumers reach
-- Create/Delete through the export proxy (exports.msk_core:CreateCron/DeleteCron).
if IS_CORE then

local CronJobs, CronJobsAt = {}, {}
local CronJobUniqueIds = {}

local function createUniqueId()
    local id = math.random(1, 999999999999)

    if CronJobUniqueIds[id] then
        return createUniqueId()
    end

    CronJobUniqueIds[id] = id
    return id
end

local function getTime(time, date)
    if date.m then time = time + (60 * date.m) end
    if date.h then time = time + (60 * 60 * date.h) end
    if date.d then time = time + (60 * 60 * 24 * date.d) end
    if date.w then time = time + (60 * 60 * 24 * 7 * date.w) end
    return time
end

-- Both ticks run right after the start of every minute. A fixed 60 second
-- timeout drifted, and a tick that slipped past the minute a job waited for
-- skipped it.
local function nextMinuteDelay()
    return (60 - os.time() % 60) * 1000 + 100
end

local function minuteOf(timestamp)
    return timestamp // 60
end

-- Copy of a job list. Callbacks may create or delete jobs while a tick walks
-- the list, and deleting from the live list made the loop read past its end.
local function snapshot(list)
    local copy = {}
    for i = 1, #list do copy[i] = list[i] end
    return copy
end

local function removeJob(list, uniqueId)
    for i = 1, #list do
        if list[i].uniqueId == uniqueId then
            table.remove(list, i)
            break
        end
    end

    CronJobUniqueIds[uniqueId] = nil
end

local function runJob(job, info)
    -- pcall so that one broken job cannot end the scheduler for all of them.
    local ok, err = pcall(job.cb, job.uniqueId, job.data, info)

    if not ok then
        MSK.Logging('error', ('Cron job %s failed: %s'):format(job.uniqueId, err))
    end
end

local function tickCronJob()
    local currTime = os.time()
    local currMinute = minuteOf(currTime)
    local info = {
        timestamp = currTime,
        d = tonumber(os.date('%d', currTime)),
        h = tonumber(os.date('%H', currTime)),
        m = tonumber(os.date('%M', currTime)),
    }

    for _, job in ipairs(snapshot(CronJobs)) do
        -- Deleted by a callback earlier in this tick.
        if CronJobUniqueIds[job.uniqueId] and minuteOf(job.timestamp) <= currMinute then
            -- Due or overdue. Comparing day, hour and minute alone ignored month
            -- and year, so a job fired in the wrong month or waited a month.
            if type(job.date) == 'table' then
                local nextTime = getTime(job.timestamp, job.date)

                if nextTime <= job.timestamp then
                    -- No interval to add, it can only run once.
                    removeJob(CronJobs, job.uniqueId)
                else
                    while minuteOf(nextTime) <= currMinute do
                        nextTime = getTime(nextTime, job.date)
                    end

                    job.timestamp = nextTime
                end
            else
                -- A job created from a plain timestamp runs once and is done.
                removeJob(CronJobs, job.uniqueId)
            end

            runJob(job, info)
        end
    end

    SetTimeout(nextMinuteDelay(), tickCronJob)
end
tickCronJob()

local function tickCronJobAt()
    local currTime = os.time()
    local currMinute = minuteOf(currTime)
    local currD = os.date('*t', currTime).wday
    local currH = tonumber(os.date('%H', currTime))
    local currM = tonumber(os.date('%M', currTime))

    for _, job in ipairs(snapshot(CronJobsAt)) do
        local date = job.date

        if CronJobUniqueIds[job.uniqueId] and job.lastMinute ~= currMinute
            and (not date.atD or currD == date.atD) and currH == date.atH and currM == date.atM then
            job.lastMinute = currMinute
            runJob(job, { timestamp = currTime, d = currD, h = currH, m = currM })
        end
    end

    SetTimeout(nextMinuteDelay(), tickCronJobAt)
end
tickCronJobAt()

---Creates a cron job and returns its id for MSK.Cron.Delete, or nil when the
---arguments are invalid. The id used to be available only as the first
---argument of the callback, so a job could not be deleted before it ran.
---@param date table|number interval { m, h, d, w }, time { atH, atM, atD } or a unix timestamp
---@param data any passed to cb
---@param cb fun(uniqueId: number, data: any, info: table)
---@return number|nil uniqueId
function MSK.Cron.Create(date, data, cb)
    local currTime = os.time()
    local timestamp = date

    -- Jobs of a resource are removed when it stops, their callback points into it.
    local owner = GetInvokingResource()

    -- Checked here, not when the job is due. A job without a usable time or
    -- callback used to be stored anyway, and the tick that reached it ended the
    -- scheduler for every job on the server.
    if type(date) ~= 'table' and type(date) ~= 'number' then
        MSK.Logging('error', ('MSK.Cron.Create: "date" has to be a table or a timestamp, received %s'):format(type(date)))
        return nil
    end

    if type(cb) ~= 'function' and not (type(cb) == 'table' and getmetatable(cb) and getmetatable(cb).__call) then
        MSK.Logging('error', ('MSK.Cron.Create: "cb" has to be a function, received %s'):format(type(cb)))
        return nil
    end

    if type(date) == "table" then
        timestamp = getTime(currTime, date)
    end

    -- Only a table can describe an "at" job. A plain timestamp equal to now
    -- used to land here and fail on date.atH.
    if type(date) == "table" and currTime == timestamp then
        local function isWhole(value, min, max)
            return type(value) == 'number' and value % 1 == 0 and value >= min and value <= max
        end

        if not isWhole(date.atH, 0, 23) then
            MSK.Logging('error', 'MSK.Cron.Create: "atH" has to be an hour from 0 to 23, or the date needs m, h, d or w')
            return nil
        end

        if date.atM ~= nil and not isWhole(date.atM, 0, 59) then
            MSK.Logging('error', 'MSK.Cron.Create: "atM" has to be a minute from 0 to 59')
            return nil
        end

        -- Without atD the job runs every day. A value outside 1 to 7 never
        -- matched a weekday and the job silently never ran.
        if date.atD ~= nil and not isWhole(date.atD, 1, 7) then
            MSK.Logging('error', 'MSK.Cron.Create: "atD" has to be a weekday from 1 (Sunday) to 7 (Saturday), or nil for every day')
            return nil
        end

        -- A missing atM means the full hour. It used to be compared as nil
        -- against the current minute, so the job was accepted and never ran.
        -- Stored as a copy, the caller's table stays untouched.
        date = { atH = date.atH, atM = date.atM or 0, atD = date.atD }

        local uniqueId = createUniqueId()

        CronJobsAt[#CronJobsAt + 1] = {
            uniqueId = uniqueId,
            date = date,
            data = data,
            cb = cb,
            owner = owner,
        }

        -- atD is compared against os.date('*t').wday, where 1 is Sunday.
        logging('debug', 'Created CronJobAT at: ' .. os.date('%d.%m.%Y %H:%M:%S', os.time()), 'Will be executed at: ' .. ('%s:%s'):format(date.atH, date.atM) .. ' ' .. ('Day %s (1 = Sunday ... 7 = Saturday)'):format(date.atD or 'everyday'))

        return uniqueId
    end

    local uniqueId = createUniqueId()

    CronJobs[#CronJobs + 1] = {
        uniqueId = uniqueId,
        timestamp = timestamp,
        date = date,
        data = data,
        cb = cb,
        owner = owner,
    }

    logging('debug', 'Created CronJob at: ' .. os.date('%d.%m.%Y %H:%M:%S', os.time()), 'Will be executed at: ' .. os.date('%d.%m.%Y %H:%M:%S', timestamp))

    return uniqueId
end
MSK.CreateCron = MSK.Cron.Create
exports('CreateCron', MSK.Cron.Create)

-- AddEventHandler, NOT RegisterNetEvent. As a net event any client could call
-- TriggerServerEvent('msk_core:createCron', ...) and schedule jobs on the
-- server. A client cannot send a function, so the `cb` would arrive as a string
-- or table, and calling it a minute later ended the scheduler thread and with
-- it every cron job on the server. Server-side TriggerEvent still reaches this.
AddEventHandler('msk_core:createCron', MSK.Cron.Create)

function MSK.Cron.Delete(id)
    if not id then return end
    if not CronJobUniqueIds[id] then return end
    local found = false

    -- table.remove, not `= nil`. Setting an array slot to nil leaves a hole,
    -- and the tick loops walk 1..#CronJobs, so the very next tick indexed that
    -- hole and stopped the scheduler. Deleting a cron job used to break cron.
    for i = 1, #CronJobs do
        if CronJobs[i].uniqueId == id then
            table.remove(CronJobs, i)
            CronJobUniqueIds[id] = nil
            found = true
            break
        end
    end

    if found then return found end

    for i = 1, #CronJobsAt do
        if CronJobsAt[i].uniqueId == id then
            table.remove(CronJobsAt, i)
            CronJobUniqueIds[id] = nil
            found = true
            break
        end
    end

    return found
end
MSK.DeleteCron = MSK.Cron.Delete
exports('DeleteCron', MSK.Cron.Delete)

--------------------------------------------------------------------------------
-- Cron expressions
--
--   MSK.Cron.Schedule('*/15 * * * *', function(id, info) ... end)   -- every 15 minutes
--   MSK.Cron.Schedule('0 20 * * fri', cb)                            -- Fridays 20:00
--   MSK.Cron.Schedule('@daily', cb)                                  -- every day 00:00
--
-- Five fields: minute (0-59), hour (0-23), day of month (1-31), month (1-12 or
-- jan-dec), day of week (0-7 or sun-sat, 0 and 7 are Sunday). Each field takes
-- *, a value, a range (1-5), a list (1,15,30) and a step (*/10, 8-18/2).
-- As in classic cron, when day of month AND day of week are both restricted,
-- a day matches if either of them does.
--
-- The callback gets (id, { timestamp, runs }). Returning false from it removes
-- the task. Tasks of a resource are removed when that resource stops.
-- Times are the server's local time.
--------------------------------------------------------------------------------
local MACROS = {
    ['@yearly'] = '0 0 1 1 *',
    ['@annually'] = '0 0 1 1 *',
    ['@monthly'] = '0 0 1 * *',
    ['@weekly'] = '0 0 * * 0',
    ['@daily'] = '0 0 * * *',
    ['@midnight'] = '0 0 * * *',
    ['@hourly'] = '0 * * * *',
}

local MONTH_NAMES = { jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12 }
local DAY_NAMES = { sun = 0, mon = 1, tue = 2, wed = 3, thu = 4, fri = 5, sat = 6 }

local FIELDS = {
    { name = 'minute', min = 0, max = 59 },
    { name = 'hour', min = 0, max = 23 },
    { name = 'day of month', min = 1, max = 31 },
    { name = 'month', min = 1, max = 12, names = MONTH_NAMES },
    { name = 'day of week', min = 0, max = 7, names = DAY_NAMES },
}

local function parseField(text, field)
    local allowed = {}

    local function toValue(token)
        local value = tonumber(token) or (field.names and field.names[token:lower()])
        if not value or value < field.min or value > field.max then
            error(('invalid value "%s" in %s field (allowed %s-%s)'):format(token, field.name, field.min, field.max), 0)
        end
        return value
    end

    for part in text:gmatch('[^,]+') do
        local range, step = part:match('^([^/]+)/(%d+)$')
        range = range or part
        step = tonumber(step) or 1

        if step < 1 then
            error(('invalid step in %s field'):format(field.name), 0)
        end

        local from, to

        if range == '*' then
            from, to = field.min, field.max
        else
            local first, last = range:match('^(%w+)%-(%w+)$')

            if first then
                from, to = toValue(first), toValue(last)
            else
                from = toValue(range)
                -- "5/15" means: starting at 5, every 15 up to the maximum.
                to = part:find('/', 1, true) and field.max or from
            end
        end

        if from > to then
            error(('range %s-%s in %s field runs backwards'):format(from, to, field.name), 0)
        end

        for value = from, to, step do
            allowed[value] = true
        end
    end

    return allowed
end

local function parseExpression(expression)
    assert(type(expression) == 'string', 'Parameter "expression" has to be a string')

    local normalized = MACROS[expression:lower()] or expression
    local parts = {}

    for part in normalized:gmatch('%S+') do
        parts[#parts + 1] = part
    end

    if #parts ~= 5 then
        error(('expected 5 fields, got %s'):format(#parts), 0)
    end

    local parsed = {}
    for i = 1, 5 do
        parsed[i] = parseField(parts[i], FIELDS[i])
    end

    -- 7 is a second name for Sunday.
    if parsed[5][7] then parsed[5][0] = true end

    return {
        minute = parsed[1],
        hour = parsed[2],
        day = parsed[3],
        month = parsed[4],
        weekday = parsed[5],
        dayRestricted = parts[3]:sub(1, 1) ~= '*',
        weekdayRestricted = parts[5]:sub(1, 1) ~= '*',
    }
end

local function dayMatches(schedule, date)
    local byDay = schedule.day[date.day] == true
    local byWeekday = schedule.weekday[date.wday - 1] == true

    if schedule.dayRestricted and schedule.weekdayRestricted then
        return byDay or byWeekday
    end

    return byDay and byWeekday
end

local function matches(schedule, date)
    return schedule.minute[date.min] == true
        and schedule.hour[date.hour] == true
        and schedule.month[date.month] == true
        and dayMatches(schedule, date)
end

-- Next matching minute after `from`. Skips whole months, days and hours that
-- cannot match instead of testing minute by minute.
local function nextRun(schedule, from)
    local t = (from - from % 60) + 60

    for _ = 1, 200000 do
        local date = os.date('*t', t)

        if not schedule.month[date.month] then
            t = os.time({ year = date.year, month = date.month + 1, day = 1, hour = 0, min = 0, sec = 0 })
        elseif not dayMatches(schedule, date) then
            t = os.time({ year = date.year, month = date.month, day = date.day + 1, hour = 0, min = 0, sec = 0 })
        elseif not schedule.hour[date.hour] then
            t = os.time({ year = date.year, month = date.month, day = date.day, hour = date.hour + 1, min = 0, sec = 0 })
        elseif not schedule.minute[date.min] then
            t = t + 60
        else
            return t
        end
    end
end

local tasks = {}
local schedulerRunning = false

local function runDueTasks()
    local now = os.time()
    local date = os.date('*t', now)
    local minuteKey = now - now % 60

    for id, task in pairs(tasks) do
        if task.lastMinute ~= minuteKey and matches(task.schedule, date) then
            task.lastMinute = minuteKey
            task.runs = task.runs + 1

            local ok, result = pcall(task.cb, id, { timestamp = now, runs = task.runs })

            if not ok then
                MSK.Logging('error', ('Cron task %s (%s) of "%s" failed: %s'):format(id, task.expression, task.owner, result))
            elseif result == false then
                tasks[id] = nil
            end
        end
    end
end

local function startScheduler()
    if schedulerRunning then return end
    schedulerRunning = true

    CreateThread(function()
        while next(tasks) do
            -- Sleep to just past the start of the next minute.
            local now = os.time()
            Wait((60 - now % 60) * 1000 + 50)
            runDueTasks()
        end

        schedulerRunning = false
    end)
end

---Checks an expression without scheduling anything.
---@param expression string
---@return boolean valid, string? reason
function MSK.Cron.IsValid(expression)
    local ok, err = pcall(parseExpression, expression)
    return ok, not ok and tostring(err) or nil
end
exports('IsCronValid', MSK.Cron.IsValid)

---Runs `cb` whenever the cron expression matches.
---@param expression string
---@param cb fun(id: number, info: { timestamp: number, runs: number }): boolean?
---@return number id
function MSK.Cron.Schedule(expression, cb)
    assert(cb ~= nil, 'Parameter "cb" is nil on function MSK.Cron.Schedule')

    local ok, schedule = pcall(parseExpression, expression)
    if not ok then
        error(('Invalid cron expression "%s": %s'):format(tostring(expression), schedule), 2)
    end

    local id = createUniqueId()

    tasks[id] = {
        expression = expression,
        schedule = schedule,
        cb = cb,
        owner = GetInvokingResource() or 'msk_core',
        runs = 0,
    }

    startScheduler()
    return id
end
exports('ScheduleCron', MSK.Cron.Schedule)

---@param id number
---@return boolean removed
function MSK.Cron.Unschedule(id)
    if not tasks[id] then return false end

    tasks[id] = nil
    CronJobUniqueIds[id] = nil
    return true
end
exports('UnscheduleCron', MSK.Cron.Unschedule)

---Timestamp of the next run of a scheduled task id or of an expression.
---@param idOrExpression number|string
---@return number? timestamp
function MSK.Cron.GetNextRun(idOrExpression)
    local schedule

    if type(idOrExpression) == 'string' then
        local ok, parsed = pcall(parseExpression, idOrExpression)
        if not ok then return nil end
        schedule = parsed
    else
        local task = tasks[idOrExpression]
        if not task then return nil end
        schedule = task.schedule
    end

    return nextRun(schedule, os.time())
end
exports('CronNextRun', MSK.Cron.GetNextRun)

AddEventHandler('onResourceStop', function(resource)
    for id, task in pairs(tasks) do
        if task.owner == resource then
            tasks[id] = nil
            CronJobUniqueIds[id] = nil
        end
    end

    -- Jobs from MSK.Cron.Create too. They used to keep calling into the
    -- stopped resource every time they were due.
    for _, list in ipairs({ CronJobs, CronJobsAt }) do
        for i = #list, 1, -1 do
            if list[i].owner == resource then
                CronJobUniqueIds[list[i].uniqueId] = nil
                table.remove(list, i)
            end
        end
    end
end)

else
    -- Consumer view: route to the single scheduler inside msk_core.
    function MSK.Cron.Create(...) return exports.msk_core:CreateCron(...) end
    function MSK.Cron.Delete(...) return exports.msk_core:DeleteCron(...) end
    function MSK.Cron.Schedule(expression, cb) return exports.msk_core:ScheduleCron(expression, cb) end
    function MSK.Cron.Unschedule(id) return exports.msk_core:UnscheduleCron(id) end
    function MSK.Cron.GetNextRun(idOrExpression) return exports.msk_core:CronNextRun(idOrExpression) end
    function MSK.Cron.IsValid(expression) return exports.msk_core:IsCronValid(expression) end
    MSK.CreateCron = MSK.Cron.Create
    MSK.DeleteCron = MSK.Cron.Delete
end

-- Return the Cron table (not `true`): the consumer loader (import.lua) caches the
-- module's return value under MSK.Cron, so returning `true` here would clobber the
-- MSK.Cron table built above and leave only MSK.CreateCron/MSK.DeleteCron usable.
return MSK.Cron
