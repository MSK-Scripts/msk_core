local RegisteredCommands, RegisteredHotkeys = {}, {}

local RegisterHotkey = function(commandName, properties)
    if RegisteredCommands[commandName].properties.params then
        if RegisteredHotkeys[commandName] then
            MSK.Logging('warn', ("Command '%s' found a Registered Hotkey! You'll need a server restart to delete it."):format(commandName))
        end

        return MSK.Logging('warn', ("Command '%s' failed to RegisterHotkey! You cannot use params and register a hotkey together!"):format(commandName))
    end

    if type(properties) ~= 'table' then
        return MSK.Logging('error', ('expected "table" for parameter "hotkey", received %s'):format(type(properties)))
    end

    if properties.text and properties.key then
        RegisteredHotkeys[commandName] = properties
        RegisterKeyMapping(commandName, properties.text, properties.type or 'keyboard', properties.key)
    else
        MSK.Logging('error', ('expected "text" and "key" for parameter "hotkey", received (text: %s, key: %s)'):format(properties.text, properties.key))
    end
end

local parseArgs = function(source, args, raw, params)
    if not params then return args end

    local DoesPlayerExist = function(playerId)
        return MSK.Trigger('msk_core:doesPlayerExist', playerId)
    end

    local GetPlayerData = function(playerId)
        return MSK.Trigger('msk_core:getPlayerData', playerId)
    end

    for i=1, #params do
        local arg, param = args[i], params[i]
        local value

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
                value = GetPlayerData(value)
            end
        else
            value = arg
        end

        if not value and (not param.optional or param.optional and arg) then
            MSK.Logging('error', ("Command '%s' received an invalid %s for argument %s (%s), received '%s'^0"):format(MSK.String.Split(raw, ' ')[1] or raw, param.type, i, param.name, arg))
            MSK.Notification('Command Error', ("Command '%s' received an invalid %s for argument %s (%s), received '%s'"):format(MSK.String.Split(raw, ' ')[1] or raw, param.type, i, param.name, arg), 'error')
            return
        end

        args[param.name] = value
        args[i] = nil
    end

    return args
end

MSK.RegisterCommand = function(commandName, callback, restricted, properties)
    if type(commandName) == 'table' then
        for k, v in ipairs(commandName) do 
            MSK.RegisterCommand(v, callback, restricted, properties)
        end
        return
    end

    if RegisteredCommands[commandName] then
        MSK.Logging('info', ('Command ^3%s^0 is already registerd. Overriding Command...'):format(commandName))
    end

    RegisteredCommands[commandName] = {commandName = commandName, callback = callback, properties = properties}
    local params, showSuggestion, hotkey

    if properties then
        params = properties.params
        showSuggestion = properties.showSuggestion == nil or properties.showSuggestion
        hotkey = properties.hotkey

        RegisteredCommands[commandName].showSuggestion = showSuggestion
    end

    if params then
        for i = 1, #params do
            local param = params[i]

            if param.type then
                param.help = param.help and ('%s (type: %s)'):format(param.help, param.type) or ('(type: %s)'):format(param.type)
            end
        end
    end

    local checkPlayerAce = function()
        if not restricted then
            return true
        end

        return MSK.IsAceAllowed(commandName)
    end

    local commandHandler = function(source, args, raw)
        local aceAllowed = checkPlayerAce()
        if not aceAllowed then return end

        args = parseArgs(source, args, raw, params)
        if not args then return end

        local success, response = pcall(callback, source, args, raw)

        if not success then
            MSK.Logging('error', ("Command '%s' failed to execute! (response: %s)"):format(MSK.String.Split(raw, ' ')[1] or raw, response))
        end
    end

    RegisterCommand(commandName, commandHandler)

    if properties and showSuggestion then
        properties.name = ('/%s'):format(commandName)
        properties.showSuggestion = nil
        properties.hotkey = nil

        RegisteredCommands[commandName].properties = properties

        TriggerEvent('chat:addSuggestion', properties.name, properties.help, properties.params)
    elseif not showSuggestion then
        TriggerEvent('chat:removeSuggestion', ('/%s'):format(commandName))
    end

    if hotkey then
        RegisterHotkey(commandName, hotkey)
    end

    return RegisteredCommands[commandName]
end
exports('RegisterCommand', MSK.RegisterCommand)