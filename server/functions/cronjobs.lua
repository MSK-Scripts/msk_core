MSK.Cron = {}

local CronJobs, CronJobsAt = {}, {}
local CronJobUniqueIds = {}

local createUniqueId = function()
    local id = math.random(1, 999999999999)

    if CronJobUniqueIds[id] then
        return createUniqueId()
    end

    createUniqueId[id] = id

    return createUniqueId[id]
end

local getTime = function(time, date)
    if date.m then
        time = time + (60 * date.m)
    end

    if date.h then
        time = time + (60 * 60 * date.h)
    end

    if date.d then
        time = time + (60 * 60 * 24 * date.d)
    end

    if date.w then
        time = time + (60 * 60 * 24 * 7 * date.w)
    end

    return time
end

tickCronJob = function()
    local currTime = os.time()
    local currD = tonumber(os.date('%d', currTime))
    local currH = tonumber(os.date('%H', currTime))
    local currM = tonumber(os.date('%M', currTime))

    for i=1, #CronJobs do
        local timestamp = CronJobs[i].timestamp
        local d = tonumber(os.date('%d', timestamp))
	    local h = tonumber(os.date('%H', timestamp))
	    local m = tonumber(os.date('%M', timestamp))

        if currD == d and currH == h and currM == m then
            CronJobs[i].timestamp = getTime(timestamp, CronJobs[i].date)
            CronJobs[i].cb(CronJobs[i].id, CronJobs[i].data, {timestamp = currTime, d = currD, h = currH, m = currM})
        end
    end

    SetTimeout(60000, tickCronJob)
end
tickCronJob()

tickCronJobAt = function()
    local currTime = os.time()
    local currD = os.date('*t', currTime).wday
    local currH = tonumber(os.date('%H', currTime))
    local currM = tonumber(os.date('%M', currTime))

    for i=1, #CronJobsAt do
        if (not CronJobsAt[i].date.atD or CronJobsAt[i].date.atD and currD == CronJobsAt[i].date.atD) and currH == CronJobsAt[i].date.atH and currM == CronJobsAt[i].date.atM then
            CronJobsAt[i].cb(CronJobs[i].id, CronJobsAt[i].data, {timestamp = currTime, d = currD, h = currH, m = currM})
        end
    end

    SetTimeout(60000, tickCronJobAt)
end
tickCronJobAt()

MSK.Cron.Create = function(date, data, cb)
    local currTime = os.time()
    local timestamp = date

    if type(date) == "table" then
        timestamp = getTime(currTime, date)
    end

    if currTime == timestamp then
        if date.atH and date.atH > 23 then 
            return print('[^1ERROR^0]', 'Value "atH" can\'t be greater than 23 on MSK.Cron.Create')
        end

        if date.atM and date.atM > 59 then 
            return print('[^1ERROR^0]', 'Value "atM" can\'t be greater than 59 on MSK.Cron.Create')
        end

        CronJobsAt[#CronJobsAt + 1] = {
            uniqueId = createUniqueId(),
            date = date,
            data = data,
            cb = cb
        }

        logging('debug', 'Created CronJobAT at: ' .. os.date('%d.%m.%Y %H:%M:%S', os.time()), 'Will be executed at: ' .. ('%s:%s'):format(date.atH, date.atM) .. ' ' .. ('Day %s (1-7 = Mo - Su)'):format(date.atD or 'everyday'))
    else
        CronJobs[#CronJobs + 1] = {
            uniqueId = createUniqueId(),
            timestamp = timestamp,
            date = date,
            data = data,
            cb = cb
        }

        logging('debug', 'Created CronJob at: ' .. os.date('%d.%m.%Y %H:%M:%S', os.time()), 'Will be executed at: ' .. os.date('%d.%m.%Y %H:%M:%S', CronJobs[#CronJobs].timestamp))
    end
end
MSK.CreateCron = MSK.Cron.Create
exports('CreateCron', MSK.Cron.Create)
RegisterNetEvent('msk_core:createCron', MSK.Cron.Create)

MSK.Cron.Delete = function(id)
    if not id then return end
    if not CronJobUniqueIds[id] then return end
    local found = false

    for i=1, #CronJobs do
        if CronJobs[i].uniqueId == id then
            CronJobs[i] = nil
            CronJobUniqueIds[id] = nil
            found = true
            break
        end
    end

    if found then return found end

    for i=1, #CronJobsAt do
        if CronJobsAt[i].uniqueId == id then
            CronJobsAt[i] = nil
            CronJobUniqueIds[id] = nil
            found = true
            break
        end
    end

    return found
end
MSK.DeleteCron = MSK.Cron.Delete
exports('DeleteCron', MSK.Cron.Delete)