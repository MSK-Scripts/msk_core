local CronJobs, CronJobsAt = {}, {}

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

    for i=1, #CronJobs, 1 do
        local timestamp = CronJobs[i].timestamp
        local d = tonumber(os.date('%d', timestamp))
	    local h = tonumber(os.date('%H', timestamp))
	    local m = tonumber(os.date('%M', timestamp))

        if currD == d and currH == h and currM == m then
            logging('debug', 'tickCronJob', os.date('%d.%m.%Y %H:%M:%S', currTime))
            CronJobs[i].timestamp = getTime(timestamp, CronJobs[i].date)
            CronJobs[i].cb(CronJobs[i].data, {timestamp = currTime, d = currD, h = currH, m = currM})
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

    for i=1, #CronJobsAt, 1 do
        if (not CronJobsAt[i].date.atD or CronJobsAt[i].date.atD and currD == CronJobsAt[i].date.atD) and currH == CronJobsAt[i].date.atH and currM == CronJobsAt[i].date.atM then
            CronJobsAt[i].cb(CronJobsAt[i].data, {timestamp = currTime, d = currD, h = currH, m = currM})
        end
    end

    SetTimeout(60000, tickCronJobAt)
end
tickCronJobAt()

MSK.CreateCron = function(date, data, cb)
    local currTime = os.time()
    local timestamp = date

    if type(date) == "table" then
        timestamp = getTime(currTime, date)
    end

    if currTime == timestamp then
        if date.atH and date.atH > 23 then 
            return print('[^1ERROR^0]', 'Value "atH" can\'t be greater than 23 on MSK.CreateCron')
        end

        if date.atM and date.atM > 59 then 
            return print('[^1ERROR^0]', 'Value "atM" can\'t be greater than 59 on MSK.CreateCron')
        end

        CronJobsAt[#CronJobsAt + 1] = {
            date = date,
            data = data,
            cb = cb
        }

        logging('debug', 'Created CronJobAT at: ' .. os.date('%d.%m.%Y %H:%M:%S', os.time()), 'Will be executed at: ' .. ('%s:%s'):format(date.atH, date.atM) .. ' ' .. ('Day %s (1-7 = Mo - Su)'):format(date.atD or 'everyday'))
    else
        CronJobs[#CronJobs + 1] = {
            timestamp = timestamp,
            date = date,
            data = data,
            cb = cb
        }

        logging('debug', 'Created CronJob at: ' .. os.date('%d.%m.%Y %H:%M:%S', os.time()), 'Will be executed at: ' .. os.date('%d.%m.%Y %H:%M:%S', CronJobs[#CronJobs].timestamp))
    end
end
exports('CreateCron', MSK.CreateCron)
RegisterNetEvent('msk_core:createCron', MSK.CreateCron)