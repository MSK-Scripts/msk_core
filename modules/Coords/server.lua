local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Coords = {}

if IS_CORE then
    function Coords.Show(playerId)
        if not playerId or playerId == 0 then return end
        TriggerClientEvent('msk_core:showCoords', playerId)
    end

    function Coords.Active(playerId)
        if not playerId or playerId == 0 then return end
        return MSK.Trigger('msk_core:doesShowCoords', playerId)
    end

    function Coords.Hide(playerId)
        if not playerId or playerId == 0 then return end
        TriggerClientEvent('msk_core:hideCoords', playerId)
    end

    function Coords.Copy(playerId, targetId)
        if not playerId or playerId == 0 then return end
        local coords

        if targetId then
            coords = MSK.Player[targetId].coords
        else
            coords = MSK.Player[playerId].coords
        end

        if coords then
            TriggerClientEvent('msk_core:copyCoords', playerId, coords)
        end
    end

    exports('ShowCoords', Coords.Show)
    exports('DoesShowCoords', Coords.Active)
    exports('HideCoords', Coords.Hide)
    exports('CopyCoords', Coords.Copy)

    MSK.ShowCoords = Coords.Show        -- Backwards compatibility
    MSK.DoesShowCoords = Coords.Active  -- Backwards compatibility
    MSK.Coords = Coords

    -- Commands (need the Command module; loaded BEFORE Coords in boot/server)
    if Config.showCoords.enable then
        MSK.RegisterCommand(Config.showCoords.command, function(source, args, raw)
            Coords.Show(args.playerId or source)
        end, {
            allowConsole = false,
            restricted = Config.showCoords.groups,
            help = 'Show your own Coords',
            params = {
                {name = 'playerId', type = 'playerId', help = 'Target players server id', optional = true}
            }
        })
    end

    if Config.copyCoords.enable then
        MSK.RegisterCommand(Config.copyCoords.command, function(source, args, raw)
            Coords.Copy(source, args.playerId)
        end, {
            allowConsole = false,
            restricted = Config.copyCoords.groups,
            help = 'Copy coords to clipboard',
            params = {
                {name = 'playerId', type = 'playerId', help = 'Target players server id', optional = true}
            }
        })
    end
else
    function Coords.Show(playerId) return exports.msk_core:ShowCoords(playerId) end
    function Coords.Hide(playerId) return exports.msk_core:HideCoords(playerId) end
    function Coords.Active(playerId) return exports.msk_core:DoesShowCoords(playerId) end
    function Coords.Copy(playerId, targetId) return exports.msk_core:CopyCoords(playerId, targetId) end
end

return Coords
