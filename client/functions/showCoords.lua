MSK.Coords = {}

local showCoords = false

MSK.Coords.Show = function()
	if showCoords then
		showCoords = false
		return
	end

	showCoords = true
	CreateThread(startShowCoordsThread)
end
MSK.ShowCoords = MSK.Coords.Show -- Support for old Scripts
exports('ShowCoords', MSK.Coords.Show)
RegisterNetEvent('msk_core:showCoords', MSK.Coords.Show)

MSK.Coords.Active = function()
	return showCoords
end
MSK.DoesShowCoords = MSK.Coords.Active -- Support for old Scripts
exports('CoordsActive', MSK.Coords.Active)
exports('DoesShowCoords', MSK.Coords.Active) -- Support for old Scripts

MSK.Coords.Hide = function()
	showCoords = false
end
exports('HideCoords', MSK.Coords.Hide)
RegisterNetEvent('msk_core:hideCoords', MSK.Coords.Hide)

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
		
		local playerX, playerY, playerZ = table.unpack(MSK.Player.coords)
		local playerH = MSK.Player.heading

		DrawGenericText(("~g~X~w~ = ~r~%s ~g~Y~w~ = ~r~%s ~g~Z~w~ = ~r~%s ~g~H~w~ = ~r~%s~s~"):format(MSK.Math.Round(playerX, 2), MSK.Math.Round(playerY, 2), MSK.Math.Round(playerZ, 2), MSK.Math.Round(playerH, 2)))

		Wait(sleep)
	end
end