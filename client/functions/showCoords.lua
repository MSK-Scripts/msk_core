local showCoords = false

MSK.ShowCoords = function()
	showCoords = not showCoords

	if showCoords then
		CreateThread(startShowCoordsThread)
	end
end
exports('ShowCoords', MSK.ShowCoords)
RegisterNetEvent('msk_core:showCoords', MSK.ShowCoords)

MSK.DoesShowCoords = function()
	return showCoords
end
exports('DoesShowCoords', MSK.DoesShowCoords)

MSK.Register('msk_core:doesShowCoords', function(source)
	return showCoords
end)

local DrawGenericText = function(text)
	SetTextColour(186, 186, 186, 255)
	SetTextFont(7)
	SetTextScale(0.378, 0.378)
	SetTextWrap(0.0, 1.0)
	SetTextCentre(false)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 205)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(0.40, 0.00)
end

startShowCoordsThread = function()
	while showCoords do
		local sleep = 1
		local playerPed = PlayerPedId()
		local playerX, playerY, playerZ = table.unpack(GetEntityCoords(playerPed))
		local playerH = GetEntityHeading(playerPed)

		DrawGenericText(("~g~X~w~ = ~r~%s ~g~Y~w~ = ~r~%s ~g~Z~w~ = ~r~%s ~g~H~w~ = ~r~%s~s~"):format(MSK.Round(playerX, 2), MSK.Round(playerY, 2), MSK.Round(playerZ, 2), MSK.Round(playerH, 2)))

		Wait(sleep)
	end
end