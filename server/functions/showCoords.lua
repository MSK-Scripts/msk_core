MSK.Coords = {}

if Config.showCoords.enable then
	MSK.RegisterCommand(Config.showCoords.command, function(source, args, raw)
		MSK.Coords.Show(args.playerId or source)
	end, {
		allowConsole = false,
		restricted = Config.showCoords.groups,
		help = 'Show your own Coords',
		params = {
			{name = 'playerId', type = 'playerId', help = 'Target players server id', optional = true}
		}
	})
end

MSK.Coords.Show = function(playerId)
	if not playerId or playerId == 0 then return end
	TriggerClientEvent('msk_core:showCoords', playerId)
end
MSK.ShowCoords = MSK.Coords.Show -- Support for old Scripts
exports('ShowCoords', MSK.Coords.Show)

MSK.Coords.Active = function(playerId)
	if not playerId or playerId == 0 then return end
	return MSK.Trigger('msk_core:doesShowCoords', playerId)
end
MSK.DoesShowCoords = MSK.Coords.Active -- Support for old Scripts
exports('DoesShowCoords', MSK.Coords.Active)

MSK.Coords.Hide = function(playerId)
	if not playerId or playerId == 0 then return end
	TriggerClientEvent('msk_core:hideCoords', playerId)
end
exports('HideCoords', MSK.Coords.Hide)