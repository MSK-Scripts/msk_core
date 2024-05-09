AddEventHandler('playerDropped', function(reason)
    -- Insert the Webook Link here
    local discordWebhookLink = ""

    if not Config.AntiCombatlog.enable then return end
    local src = source
    local playerName = GetPlayerName(src)
    local coords = GetEntityCoords(GetPlayerPed(src))
    local time = os.date('%d.%m.%Y %H:%M', os.time())

	TriggerClientEvent('msk_core:anticombatlog', -1, {
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

    if Config.AntiCombatlog.console.enable then
        local logText = Config.AntiCombatlog.console.text:format(
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

    if Config.AntiCombatlog.discord.enable then
        MSK.AddWebhook(
            discordWebhookLink, 
            Config.AntiCombatlog.discord.color, 
            Config.AntiCombatlog.discord.botName, 
            Config.AntiCombatlog.discord.botAvatar, 
            Config.AntiCombatlog.discord.title, 
            Config.AntiCombatlog.discord.text:format(playerName, src),
            {
                {name = "Reason", value = reason, inline = false},
                {name = "Coords", value = coords, inline = false},
                {name = "Identifier", value = ("%s\n%s\n%s"):format(getIdentifier('steam:'), getIdentifier('license:'), getIdentifier('discord:')), inline = false},
            },
            {text = ("© %s • %s"):format(Config.AntiCombatlog.discord.botName, time), link = Config.AntiCombatlog.discord.botAvatar}
        )
    end
end)