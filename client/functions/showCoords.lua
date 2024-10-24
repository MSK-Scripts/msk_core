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
MSK.ShowCoords = MSK.Coords.Show -- Backwards compatibility
exports('ShowCoords', MSK.Coords.Show)
RegisterNetEvent('msk_core:showCoords', MSK.Coords.Show)

MSK.Coords.Active = function()
	return showCoords
end
MSK.DoesShowCoords = MSK.Coords.Active -- Backwards compatibility
exports('CoordsActive', MSK.Coords.Active)
MSK.Register('msk_core:doesShowCoords', MSK.Coords.Active)

MSK.Coords.Hide = function()
	showCoords = false
end
exports('HideCoords', MSK.Coords.Hide)
RegisterNetEvent('msk_core:hideCoords', MSK.Coords.Hide)

MSK.Coords.Copy = function(coords)
	if not coords then coords = MSK.Player.coords end	
	local x, y, z, h = table.unpack(coords)
	
	local newCoords = {x = MSK.Math.Round(x, 2), y = MSK.Math.Round(y, 2), z = MSK.Math.Round(z, 2)}
	newCoords.h = h and MSK.Math.Round(h, 2)

	SendNUIMessage({
		action = "copyCoords",
		value = MSK.CoordsToString(newCoords),
	})
end
exports('CopyCoords', MSK.Coords.Copy)
RegisterNetEvent('msk_core:copyCoords', MSK.Coords.Copy)

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
		
		local x, y, z = table.unpack(MSK.Player.coords)
		local h = MSK.Player.heading

		DrawGenericText(("~g~X~w~ = ~r~%s ~g~Y~w~ = ~r~%s ~g~Z~w~ = ~r~%s ~g~H~w~ = ~r~%s~s~"):format(MSK.Math.Round(x, 2), MSK.Math.Round(y, 2), MSK.Math.Round(z, 2), MSK.Math.Round(h, 2)))

		Wait(sleep)
	end
end