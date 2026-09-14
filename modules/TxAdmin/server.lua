--------------------------------------------------------------------------------
-- MSK.TxAdmin (server)
--
-- Shows txAdmin announcements, direct messages and restart warnings as MSK
-- notifications. Switched on per message type in Config.TxAdmin.
--
-- txAdmin keeps showing its own message as well. To only see the MSK one, hide
-- the txAdmin default in server.cfg:
--   setr txAdmin-hideDefaultAnnouncement true
--   setr txAdmin-hideDefaultDirectMessage true
--   setr txAdmin-hideDefaultScheduledRestartWarning true
--------------------------------------------------------------------------------
if GetCurrentResourceName() ~= 'msk_core' then
    return true
end

local settings = Config.TxAdmin or {}

if settings.announcements then
    AddEventHandler('txAdmin:events:announcement', function(data)
        if type(data) ~= 'table' or not data.message then return end

        TriggerClientEvent('msk_core:notification', -1, {
            title = ('Announcement by %s'):format(data.author or 'txAdmin'),
            message = data.message,
            type = 'warning',
            icon = 'bullhorn',
            duration = settings.duration or 15000,
        })
    end)
end

if settings.directMessages then
    AddEventHandler('txAdmin:events:playerDirectMessage', function(data)
        if type(data) ~= 'table' or not data.message or not tonumber(data.target) then return end

        TriggerClientEvent('msk_core:notification', tonumber(data.target), {
            title = ('Message from %s'):format(data.author or 'txAdmin'),
            message = data.message,
            type = 'info',
            icon = 'envelope',
            duration = settings.duration or 15000,
        })
    end)
end

if settings.restartWarnings then
    AddEventHandler('txAdmin:events:scheduledRestart', function(data)
        if type(data) ~= 'table' or not tonumber(data.secondsRemaining) then return end

        local minutes = math.floor(tonumber(data.secondsRemaining) / 60)

        TriggerClientEvent('msk_core:notification', -1, {
            id = 'txadmin_restart',
            title = 'Server Restart',
            message = minutes > 0 and ('The server restarts in %s minute(s).'):format(minutes) or 'The server restarts now.',
            type = 'warning',
            icon = 'rotate',
            iconAnimation = 'spin',
            duration = settings.duration or 15000,
        })
    end)
end

return true
