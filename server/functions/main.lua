local RegisteredCommands = {}

MSK.Notification = function(src, title, message, info, time)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:notification', src, title, message, info, time)
end
MSK.Notify = MSK.Notification
exports('Notification', MSK.Notification)

MSK.HelpNotification = function(src, text)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:helpNotification', src, text)
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)

MSK.AdvancedNotification = function(src, text, title, subtitle, icon, flash, icontype)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:advancedNotification', src, text, title, subtitle, icon, flash, icontype)
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)

MSK.ScaleformAnnounce = function(src, header, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:scaleformNotification', src, header, text, typ, duration)
end
MSK.Scaleform = MSK.ScaleformAnnounce
exports('ScaleformAnnounce', MSK.ScaleformAnnounce)

MSK.Subtitle = function(src, message, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:subtitle', src, message, duration)
end
exports('Subtitle', MSK.Subtitle)

MSK.Spinner = function(src, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:spinner', src, text, typ, duration)
end
exports('Spinner', MSK.Spinner)

MSK.Draw3DText = function(src, coords, text, size, font)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:draw3DText', src, coords, text, size, font)
end
exports('Draw3DText', MSK.Draw3DText)

MSK.DrawGenericText = function(src, text, outline, font, size, color, position)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:drawGenericText', src, text, outline, font, size, color, position)
end
exports('DrawGenericText', MSK.DrawGenericText)

MSK.Progressbar = function(src, time, text, color)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:progressbar', src, time, text, color)
end
exports('Progressbar', MSK.Progressbar)

MSK.ProgressStop = function(src)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:progressbarStop', src)
end
exports('ProgressStop', MSK.ProgressStop)

MSK.Input = function(src, header, placeholder, field)
    return MSK.Trigger('msk_core:input', src, header, placeholder, field)
end
exports('Input', MSK.Input)

MSK.CloseInput = function(src)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:closeInput', src)
end
exports('CloseInput', MSK.CloseInput)

MSK.Numpad = function(src, pin, show)
    return MSK.Trigger('msk_core:numpad', src, pin, show)
end
exports('Numpad', MSK.Numpad)

MSK.CloseNumpad = function(src)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:closeNumpad', src)
end
exports('CloseNumpad', MSK.CloseNumpad)

MSK.IsSpawnPointClear = function(coords, maxDistance)
    if not coords then return end
    if not maxDistance then maxDistance = 5.0 end

    local nearbyVehicles = {}
    coords = vector3(coords.x, coords.y, coords.z)

    for k, vehicle in pairs(GetAllVehicles()) do
        local distance = #(coords - GetEntityCoords(vehicle))

        if distance <= maxDistance then
            nearbyVehicles[#nearbyVehicles + 1] = vehicle
        end
    end

    return #nearbyVehicles == 0
end
exports('IsSpawnPointClear', MSK.IsSpawnPointClear)

MSK.GetClosestPlayer = function(playerId, coords)
    return GetClosestEntity(playerId, coords)
end
exports('GetClosestPlayer', MSK.GetClosestPlayer)

MSK.GetClosestPlayers = function(playerId, coords, distance)
    return GetClosestEntities(playerId, coords, distance)
end
exports('GetClosestPlayers', MSK.GetClosestPlayers)

MSK.AddWebhook = function(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
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

MSK.HasItem = function(playerId, item)
    if not playerId then 
        logging('error', 'Player on Function MSK.HasItem does not exist!') 
        return
    end

    if MSK.Bridge.Framework.Type ~= 'ESX' and MSK.Bridge.Framework.Type ~= 'QBCore' then 
        logging('error', ('Function %s can not used without Framework!'):format('^3MSK.HasItem^0'))
        return
    end

    local Player = MSK.GetPlayerFromId(playerId)
    
    return Player.HasItem(item)
end
exports('HasItem', MSK.HasItem)

MSK.RegisterCommand = function(name, group, cb, console, framework, suggestion)    
    if type(name) == 'table' then
        for k, v in ipairs(name) do 
            MSK.RegisterCommand(v, group, cb, console, framework, suggestion)
        end
        return
    end

    if RegisteredCommands[name] then
        logging('info', ('Command ^3%s^0 is already registerd. Overriding Command...'):format(name))
    end
    
    addChatSuggestions(name, suggestion)    
    RegisteredCommands[name] = {group = group, cb = cb, console = console, suggestion = suggestion}

    RegisterCommand(name, function(source, args, rawCommand)
        local source = source
        local Command, error = RegisteredCommands[name], nil

        if not Command.console and source == 0 then 
            logging('error', 'You can not run this Command in Server Console!')
        else
            if Command.suggestion then 
                if Command.suggestion.validate or Command.suggestion.val then
                    if not Command.suggestion.arguments or #args ~= #Command.suggestion.arguments then
                        error = ('Invalid Argument Count (passed %s, wanted %s)'):format(#args, #Command.suggestion.arguments)
                    end
                end

                if not error and Command.suggestion.arguments then
                    local newArgs = {}

                    for k, v in ipairs(Command.suggestion.arguments) do
                        local action = v.action or v.type
                        
                        if action then
                            if action == 'number' then
                                local newArg = tonumber(args[k])

                                if newArg then
									newArgs[v.name] = newArg
								else
									error = ('Invalid Argument %s data type (passed string, wanted number)'):format(v.name)
								end
                            elseif action == 'string' then
                                local newArg = tonumber(args[k])

                                if not newArg then
									newArgs[v.name] = args[k]
								else
									error = ('Invalid Argument %s data type (passed number, wanted string)'):format(v.name)
								end
                            elseif action == 'playerId' or action == 'player' then
                                local targetId = tonumber(targetId)
                                if args[k] == 'me' then targetId = source end

                                if targetId and doesPlayerIdExist(targetId) then
                                    if action == 'player' then
                                        if (MSK.Bridge.Framework.Type == 'ESX' or MSK.Bridge.Framework.Type == 'QBCore') then
                                            local Player = MSK.GetPlayer({source = targetId})

                                            if Player then
                                                newArgs[v.name] = Player
                                            else
                                                error = ('Specified Player (ID: %s) is not online'):format(targetId)
                                            end
                                        else
                                            error = ('Specified Player not found on Argument %s (Framework not compatible)'):format(v.name)
                                        end
                                    else
                                        newArgs[v.name] = targetId
                                    end
                                else
                                    error = ('Specified PlayerId %s is not online'):format(targetId)
                                end
                            else
                                newArgs[v.name] = args[k]
                            end
                        end

                        -- Backwards compatibility
                        if not error and not newArgs[v.name] and v.val then 
                            error = ('Invalid Argument Count (passed %s, wanted %s)'):format(#args, #Command.suggestion.arguments)
                        end
                        if error then break end
                    end

                    args = newArgs
                end
            end

            if error then
                if source == 0 then
                    logging('error', error)
                else
                    MSK.Notification(source, error)
                end
            else
                if framework and (MSK.Bridge.Framework.Type == 'ESX' or MSK.Bridge.Framework.Type == 'QBCore') then
                    local Player = MSK.GetPlayer({source = source})
                    cb(Player, args, rawCommand)
                else
                    cb(source, args, rawCommand)
                end
            end
        end
    end, true)

    if type(group) == 'table' then
        for k, v in ipairs(group) do
            ExecuteCommand(('add_ace group.%s command.%s allow'):format(v, name))
        end
    else
        ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
    end
end
exports('RegisterCommand', MSK.RegisterCommand)

doesPlayerIdExist = function(playerId)
    for k, id in pairs(GetPlayers()) do
        if id == playerId then
            return true
        end
    end
    return false
end

addChatSuggestions = function(name, suggestion)
    if RegisteredCommands[name] then
        if RegisteredCommands[name].suggestion then
            TriggerClientEvent('chat:removeSuggestion', -1, '/' .. name)
        end
    end

    if suggestion then
        if not suggestion.arguments then suggestion.arguments = {} end
        if not suggestion.help then suggestion.help = '' end
    
        TriggerClientEvent('chat:addSuggestion', -1, '/' .. name, suggestion.help, suggestion.arguments)
    end
end