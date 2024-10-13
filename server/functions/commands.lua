local RegisteredCommands = {}

AddEventHandler('playerJoining', function()
    local playerId = source

    for commandName, data in pairs(RegisteredCommands) do
        local properties = data.properties

        if properties and data.showSuggestion then
            TriggerClientEvent('chat:addSuggestion', playerId, properties.name, properties.help, properties.params)
        end
    end
end)

local parseArgs = function(source, args, raw, params)
    if not params then return args end

    for i=1, #params do
        local arg, param = args[i], params[i]
        local value

        -- Backwards compatibility
        if param.action then
            param.type = param.action
            param.action = nil
        end

        -- Backwards compatibility
        if param.val ~= nil then
            param.optional = not param.val
            param.val = nil
        end

        if param.type == 'number' then
            value = tonumber(arg)
        elseif param.type == 'string' then
            value = not tonumber(arg) and arg
        elseif param.type == 'playerId' then
            value = arg == 'me' and source or tonumber(arg)

            if not value or not DoesPlayerExist(value) then
                value = false
            end
        elseif param.type == 'player' then
            value = arg == 'me' and source or tonumber(arg)

            if not value or not DoesPlayerExist(value) then
                value = false
            end

            if value then
                value = MSK.GetPlayer({source = value})
            end
        else
            value = arg
        end

        if not value and (not param.optional or param.optional and arg) then
            if source == 0 then
                return MSK.Logging('error', ("^1Command '%s' received an invalid %s for argument %s (%s), received '%s'^0"):format(MSK.String.Split(raw, ' ')[1] or raw, param.type, i, param.name, arg))
            else
                return MSK.Notification(source, 'Command Error', ("Command '%s' received an invalid %s for argument %s (%s), received '%s'"):format(MSK.String.Split(raw, ' ')[1] or raw, param.type, i, param.name, arg), 'error')
            end
        end

        args[param.name] = value
        args[i] = nil
    end

    return args
end

MSK.RegisterCommand = function(commandName, callback, properties, ...)
    if ... ~= nil then
        -- Backwards compatibility
        warn(('Command "%s" is using deprecated syntax for MSK.RegisterCommand. Please update to to new syntax.'):format(commandName))
        return MSK._RegisterCommand(commandName, callback, properties, ...)
    end

    if type(commandName) == 'table' then
        for k, v in ipairs(commandName) do 
            MSK.RegisterCommand(v, callback, properties)
        end
        return
    end

    if RegisteredCommands[commandName] then
        MSK.Logging('info', ('Command ^3%s^0 is already registerd. Overriding Command...'):format(commandName))
    end

    RegisteredCommands[commandName] = {commandName = commandName, callback = callback, properties = properties}
    local params, restricted, showSuggestion, allowConsole, framework

    if properties then
        params = properties.params
        restricted = properties.restricted
        showSuggestion = properties.showSuggestion == nil or properties.showSuggestion
        allowConsole = properties.allowConsole == nil or properties.allowConsole
        framework = properties.framework

        RegisteredCommands[commandName].showSuggestion = showSuggestion
        RegisteredCommands[commandName].allowConsole = allowConsole
    end

    if params then
        for i = 1, #params do
            local param = params[i]

            if param.type then
                param.help = param.help and ('%s (type: %s)'):format(param.help, param.type) or ('(type: %s)'):format(param.type)
            end
        end
    end

    local commandHandler = function(source, args, raw)
        if source == 0 and not allowConsole then
            return MSK.Logging('error', ('^1You cannot run Command ^3%s^1 in Console!^0'):format(commandName))
        end

        args = parseArgs(source, args, raw, params)
        if not args then return end

        local success, response

        -- Backwards compatibility
        if framework and (MSK.Bridge.Framework.Type == 'ESX' or MSK.Bridge.Framework.Type == 'QBCore') then
            local Player = MSK.GetPlayer({source = source})
            success, response = pcall(callback, Player, args, raw)
        else
            success, response = pcall(callback, source, args, raw)
        end

        if not success then
            MSK.Logging('error', ("^1Command '%s' failed to execute! (response: %s)"):format(MSK.String.Split(raw, ' ')[1] or raw, response))
        end
    end

    RegisterCommand(commandName, commandHandler, restricted and true)

    if restricted then
        local ace = ('command.%s'):format(commandName)

        if type(restricted) == 'string' and not IsPrincipalAceAllowed(restricted, ace) then
            MSK.AddAce(restricted, ace)
        elseif type(restricted) == 'table' then
            for i = 1, #restricted do
                local res = restricted[i]

                if not IsPrincipalAceAllowed(res, ace) then
                    MSK.AddAce(res, ace)
                end
            end
        end
    end

    if properties and showSuggestion then
        properties.name = ('/%s'):format(commandName)
        properties.restricted = nil
        properties.showSuggestion = nil
        properties.allowConsole = nil
        properties.framework = nil -- Backwards compatibility

        RegisteredCommands[commandName].properties = properties

        TriggerClientEvent('chat:addSuggestion', -1, properties.name, properties.help, properties.params)
    end
end
exports('RegisterCommand', MSK.RegisterCommand)

----------------------------------------------------------------
-- Do NOT use this! Old syntax!
----------------------------------------------------------------
MSK._RegisterCommand = function(commandName, group, cb, console, framework, suggestion)
    local properties

    if suggestion then
        properties = {
            help = suggestion.help,
            params = suggestion.arguments,
            restricted = group,
            showSuggestion = true,
            allowConsole = console,
            framework = framework
        }
    end

    MSK.RegisterCommand(commandName, cb, properties)
end