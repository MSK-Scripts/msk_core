Config = {}
----------------------------------------------------------------
Config.Debug = false
Config.VersionChecker = true
----------------------------------------------------------------
-- Only Required for MSK.RegisterCommand and MSK.HasItem // View Docu for more Information about that!
Config.Framework = 'esx' -- Set to 'standalone', 'esx' or 'qbcore'
----------------------------------------------------------------
-- /coords
Config.showCoords = {
    enable = true,
    command = 'coords',
    groups = {'superadmin', 'admin'}
}
----------------------------------------------------------------
-- Set to 'native' for FiveM Native Notification
-- Set to 'msk' for NUI Notification
-- Set to 'okok' for OKOK Notification
-- Set to 'custom' for Config.customNotification()
Config.Notification = 'msk'

Config.NotifyTypes = {
    -- https://fontawesome.com/icons
    ['general'] = {icon = 'fa-solid fa-circle-info', color = '#ffffff'},
    ['info'] = {icon = 'fa-solid fa-circle-info', color = '#75d6ff'},
    ['success'] = {icon = 'fa-solid fa-shield-check', color = '#76ee62'},
    ['warning'] = {icon = 'fa-solid fa-triangle-exclamation', color = '#ffcb11'},
    ['error'] = {icon = 'fa-solid fa-circle-exclamation', color = '#ff4a4a'},
}

Config.customNotification = function(title, message, typ, duration)
    -- Set Config.Notification = 'custom'
    -- Add your own clientside Notification here
end

Config.progressColor = "#5eb131" -- Default Color for ProgressBar
----------------------------------------------------------------
Config.LoggingTypes = {
    ['info'] = '[^4Info^0]',
    ['debug'] = '[^3DEBUG^0]',
    ['error'] = '[^1ERROR^0]',
}
----------------------------------------------------------------
Config.AntiCombatlog = {
    enable = false, -- Set to true if you want to use this Feature
    console = {
        enable = false,
        text = "Der Spieler ^3%s^0 mit der ^3ID %s^0 hat den Server verlassen.\n^4Uhrzeit:^0 %s\n^4Grund:^0 %s\n^4Identifier:^0\n    %s\n    %s\n    %s\n^4Koordinaten:^0 %s"
    },
    discord = {
        -- Webhook in sv_anticombatlog.lua
        enable = false,
        color = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
        botName = "MSK Scripts",
        botAvatar = "https://i.imgur.com/PizJGsh.png",
        title = "Player Disconnected",
        text = "Der Spieler **%s** mit der **ID %s** hat den Server verlassen."
    }
}
----------------------------------------------------------------
-- For more Information go to: https://github.com/MSK-Scripts/msk_bansystem/blob/main/README.md
Config.BanSystem = {
    enable = false, -- Set to true if you want to use this Feature

    discordLog = false, -- Set true to enable DiscordLogs // Webhook on sv_bansystem.lua
    botColor = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
    botName = "MSK Scripts",
    botAvatar = "https://i.imgur.com/PizJGsh.png",

    commands = {
        enable = true,
        groups = {'superadmin', 'admin', 'god'},
        ban = 'banPlayer',
        unbank = 'unbanPlayer'
    }
}