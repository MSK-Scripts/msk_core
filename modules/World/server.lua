function MSK.IsSpawnPointClear(coords, maxDistance)
    if not coords then return end
    if not maxDistance then maxDistance = 5.0 end

    local nearbyVehicles = {}
    coords = vector3(coords.x, coords.y, coords.z)

    for _, vehicle in pairs(GetAllVehicles()) do
        local distance = #(coords - GetEntityCoords(vehicle))

        if distance <= maxDistance then
            nearbyVehicles[#nearbyVehicles + 1] = vehicle
        end
    end

    return #nearbyVehicles == 0
end
exports('IsSpawnPointClear', MSK.IsSpawnPointClear)

function MSK.GetClosestPlayer(playerId, coords)
    return MSK.GetClosestEntity(playerId, coords)
end
exports('GetClosestPlayer', MSK.GetClosestPlayer)

function MSK.GetClosestPlayers(playerId, coords, distance)
    return MSK.GetClosestEntities(playerId, coords, distance)
end
exports('GetClosestPlayers', MSK.GetClosestPlayers)

function MSK.AddWebhook(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
    local content = {}

    if footer then
        if time then
            footer = {
                ["text"] = footer.text .. " • " .. os.date(time),
                ["icon_url"] = footer.link
            }
        else
            footer = {
                ["text"] = footer.text,
                ["icon_url"] = footer.link
            }
        end
    end

    if fields then
        content = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = botColor,
            ["fields"] = fields,
            ["footer"] = footer
        }}
    else
        content = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = botColor,
            ["footer"] = footer
        }}
    end

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = botName,
        embeds = content,
        avatar_url = botAvatar
    }), {
        ['Content-Type'] = 'application/json'
    })
end
exports('AddWebhook', MSK.AddWebhook)

return true
