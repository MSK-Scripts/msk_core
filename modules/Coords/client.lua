local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Coords = {}

if IS_CORE then
    local showCoords = false

    local function drawGenericText(text)
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

    local function startShowCoordsThread()
        while showCoords do
            local x, y, z = table.unpack(MSK.Player.coords)
            local h = MSK.Player.heading

            drawGenericText(("~g~X~w~ = ~r~%s ~g~Y~w~ = ~r~%s ~g~Z~w~ = ~r~%s ~g~H~w~ = ~r~%s~s~"):format(MSK.Math.Round(x, 2), MSK.Math.Round(y, 2), MSK.Math.Round(z, 2), MSK.Math.Round(h, 2)))

            Wait(1)
        end
    end

    function Coords.Show()
        if showCoords then
            showCoords = false
            return
        end

        showCoords = true
        CreateThread(startShowCoordsThread)
    end

    function Coords.Active()
        return showCoords
    end

    function Coords.Hide()
        showCoords = false
    end

    function Coords.Copy(coords)
        if not coords then coords = MSK.Player.coords end
        local x, y, z, h = table.unpack(coords)

        local newCoords = {x = MSK.Math.Round(x, 2), y = MSK.Math.Round(y, 2), z = MSK.Math.Round(z, 2)}
        newCoords.h = h and MSK.Math.Round(h, 2)

        SendNUIMessage({
            action = "copyCoords",
            value = MSK.Vector.CoordsToString(newCoords),
        })
    end

    exports('ShowCoords', Coords.Show)
    exports('CoordsActive', Coords.Active)
    exports('HideCoords', Coords.Hide)
    exports('CopyCoords', Coords.Copy)

    RegisterNetEvent('msk_core:showCoords', Coords.Show)
    RegisterNetEvent('msk_core:hideCoords', Coords.Hide)
    RegisterNetEvent('msk_core:copyCoords', Coords.Copy)
    MSK.Register('msk_core:doesShowCoords', Coords.Active)

    MSK.ShowCoords = Coords.Show        -- Backwards compatibility
    MSK.DoesShowCoords = Coords.Active  -- Backwards compatibility
    MSK.Coords = Coords
else
    function Coords.Show() return exports.msk_core:ShowCoords() end
    function Coords.Hide() return exports.msk_core:HideCoords() end
    function Coords.Active() return exports.msk_core:CoordsActive() end
    function Coords.Copy(coords) return exports.msk_core:CopyCoords(coords) end
end

return Coords
