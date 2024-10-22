local drawDisplay = function(coords, text, size, color)
    if not color then color = {r = 255, g = 255, b = 255, a = 255} end
    local coords = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)

    if not size then size = 1 end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, scale * 0.5)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextDropshadow(3, 0, 0, 0, 55)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local display = function(data)
    -- data.playerId, data.playerName, data.coords, data.reason
    
    local showDisplay = true
    local timeout = MSK.SetTimeout(60000, function()
        showDisplay = false
    end)
    local text = ('%s (ID: %s)\n%s'):format(data.playerName, data.playerId, data.reason)

    CreateThread(function()
        while showDisplay do
            local sleep = 500
            
            local dist = #(data.coords - MSK.Player.coords)
            local coordsUsed = vec3(data.coords.x, data.coords.y, data.coords.z + 0.2)

            if dist <= 20.0 then
                sleep = 0
                DrawMarker(32, data.coords.x, data.coords.y, data.coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 94, 177, 49, 1, false, true, 2, false, nil, nil, false)
                drawDisplay(data.coords, text, 0.8, {r = 94, g = 177, b = 49, a = 1})
            end

            Wait(sleep)
        end
    end)
end
RegisterNetEvent('msk_core:discLogger', display)