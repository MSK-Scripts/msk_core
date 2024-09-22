AddEventHandler('playerDropped', function(reason)
    -- Insert the Webook Link here
    local discordWebhookLink = ""

    if not Config.DisconnectLogger.enable then return end
    local src = source
    local playerName = GetPlayerName(src)
    local coords = GetEntityCoords(GetPlayerPed(src))
    local time = os.date('%d.%m.%Y %H:%M', os.time())

	TriggerClientEvent('msk_core:discLogger', -1, {
        playerId = src,
        playerName = playerName,
        coords = coords,
        reason = reason
    })

    local getIdentifier = function(typ)
        for k, v in ipairs(GetPlayerIdentifiers(src)) do
            if string.match(v, typ) then
               return v
            end
        end

        return typ .. ' not found'
    end

    if Config.DisconnectLogger.console.enable then
        local logText = Config.DisconnectLogger.console.text:format(
            playerName, 
            src, 
            time, 
            reason, 
            getIdentifier('steam:'), 
            getIdentifier('license:'), 
            getIdentifier('discord:'), 
            coords
        )

        print(logText)
    end

    if Config.DisconnectLogger.discord.enable then
        MSK.AddWebhook(
            discordWebhookLink, 
            Config.DisconnectLogger.discord.color, 
            Config.DisconnectLogger.discord.botName, 
            Config.DisconnectLogger.discord.botAvatar, 
            Config.DisconnectLogger.discord.title, 
            Config.DisconnectLogger.discord.text:format(playerName, src),
            {
                {name = "Reason", value = ("%s"):format(reason), inline = false},
                {name = "Coords", value = ("%s"):format(coords), inline = false},
                {name = "Identifier", value = ("%s\n%s\n%s"):format(getIdentifier('steam:'), getIdentifier('license:'), getIdentifier('discord:')), inline = false},
            },
            {text = ("© %s • %s"):format(Config.DisconnectLogger.discord.botName, time), link = Config.DisconnectLogger.discord.botAvatar}
        )
    end
end)