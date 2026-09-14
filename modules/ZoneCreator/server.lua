--------------------------------------------------------------------------------
-- Zone creator (server, msk_core only)
--
-- Registers the command from Config.ZoneCreator. The permission is checked
-- here; the client side only ever starts when the server asks it to.
--------------------------------------------------------------------------------
if GetCurrentResourceName() ~= 'msk_core' then
    return true
end

local settings = Config.ZoneCreator

if settings and settings.enable then
    MSK.RegisterCommand(settings.command or 'zoneCreator', function(source, args)
        TriggerClientEvent('msk_core:zoneCreator', source, args.shape)
    end, {
        allowConsole = false,
        restricted = settings.groups,
        help = 'Create a zone and copy its code to the clipboard',
        params = {
            { name = 'shape', type = 'string', help = 'box, sphere or poly', optional = true },
        },
    })
end

return true
