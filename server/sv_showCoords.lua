if Config.showCoords.enable then
	MSK.RegisterCommand(Config.showCoords.command, Config.showCoords.groups, function(source, args, rawCommand)
		MSK.ShowCoords(source)
	end, false --[[console]], false --[[framework]], {help = 'Show your own Coords'})
end

MSK.ShowCoords = function(src)
	TriggerClientEvent('msk_core:showCoords', src)
end
exports('ShowCoords', MSK.ShowCoords)

MSK.DoesShowCoords = function(src)
	if not src or src == 0 then return end
	return MSK.Trigger('msk_core:doesShowCoords', src)
end
exports('DoesShowCoords', MSK.DoesShowCoords)