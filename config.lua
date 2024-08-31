Config = {}
----------------------------------------------------------------
Config.Debug = false
Config.VersionChecker = true
----------------------------------------------------------------
-- Supported Frameworks: AUTO, ESX, QBCore
-- AUTO will search for your framework
Config.Framework = 'AUTO'

-- Supported Inventories: default, custom, ox_inventory
-- Set to 'custom' if you use another inventory
-- You can add your own inventory in: server/inventories/custom.lua
Config.Inventory = 'ox_inventory'
----------------------------------------------------------------
Config.showCoords = {
    enable = true,
    command = 'coords',
    groups = {'superadmin', 'admin'}
}
----------------------------------------------------------------
-- Set to 'msk' for MSK UI Notification
-- Set to 'custom' for Config.customNotification()
-- Set to 'okok' for OKOK Notification
-- Set to 'qb-core' for QBCore Notification
-- Set to 'native' for FiveM Native Notification
Config.Notification = 'msk'

-- Only for MSK Notification
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
----------------------------------------------------------------
Config.progressColor = "#5eb131" -- Default Color for ProgressBar
----------------------------------------------------------------
Config.LoggingTypes = {
    ['info'] = '[^4Info^0]',
    ['debug'] = '[^3DEBUG^0]',
    ['error'] = '[^1ERROR^0]',
}
----------------------------------------------------------------
-- If enabled it will display a 3D Text on the position the player disconnected
Config.DisconnectLogger = {
    enable = false, -- Set to true if you want to use this Feature

    console = {
        enable = false,
        -- German: "Der Spieler ^3%s^0 mit der ^3ID %s^0 hat den Server verlassen.\n^4Uhrzeit:^0 %s\n^4Grund:^0 %s\n^4Identifier:^0\n    %s\n    %s\n    %s\n^4Koordinaten:^0 %s"
        -- English: "The player ^3%s^0 with the ^3ID %s^0 has left the server.\n^4Time:^0 %s\n^4Reason:^0 %s\n^4Identifier:^0\n %s\n %s\n %s\n^4Coordinates:^0 %s"
        text = "Der Spieler ^3%s^0 mit der ^3ID %s^0 hat den Server verlassen.\n^4Uhrzeit:^0 %s\n^4Grund:^0 %s\n^4Identifier:^0\n    %s\n    %s\n    %s\n^4Koordinaten:^0 %s"
    },

    discord = {
        enable = false, -- Set true to enable DiscordLogs // Add Webhook Link in server/functions/disconnectlogger.lua
        color = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
        botName = "MSK Scripts",
        botAvatar = "https://i.imgur.com/PizJGsh.png",
        title = "Player Disconnected",
        -- German: "Der Spieler **%s** mit der **ID %s** hat den Server verlassen."
        -- English: "The player **%s** with the **ID %s** has left the server."
        text = "Der Spieler **%s** mit der **ID %s** hat den Server verlassen."
    }
}
----------------------------------------------------------------
-- For more Information go to: https://github.com/MSK-Scripts/msk_bansystem/blob/main/README.md
Config.BanSystem = {
    enable = true, -- Set to true if you want to use this Feature

    discordLog = false, -- Set true to enable DiscordLogs // Add Webhook Link in server/functions/bansystem.lua
    botColor = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
    botName = "MSK Scripts",
    botAvatar = "https://i.imgur.com/PizJGsh.png",

    commands = {
        enable = false,
        groups = {'superadmin', 'admin', 'god'},
        ban = 'banPlayer',
        unban = 'unbanPlayer'
    }
}