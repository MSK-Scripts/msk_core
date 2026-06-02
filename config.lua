Config = {}
----------------------------------------------------------------
Config.Debug = false
Config.VersionChecker = true
----------------------------------------------------------------
-- Supported Frameworks: AUTO, ESX, QBCore, STANDALONE
-- AUTO will search for your framework
Config.Framework = 'AUTO'

-- Supported Inventories: AUTO, default, custom, ox_inventory, jaksam_inventory, core_inventory
-- AUTO will search for your inventory (ox_inventory > core_inventory > jaksam_inventory > default)
-- For ESX Default Inventory or Chezza Inventory, set to 'default'
-- Set to 'custom' if you use another inventory and add your own functions
-- You can add your own inventory in: inventories/custom.lua
Config.Inventory = 'AUTO'
----------------------------------------------------------------
Config.showCoords = {
    enable = true,
    command = 'coords',
    groups = {'superadmin', 'admin'}
}

Config.copyCoords = {
    enable = true,
    command = 'copyCoords',
    groups = {'superadmin', 'admin'}
}
----------------------------------------------------------------
-- Set to 'msk' for MSK UI Notification
-- Set to 'native' for FiveM Native Notification
-- Set to 'custom' for Config.customNotification()
-- Set to 'okok' for OKOK Notification
-- Set to 'qb-core' for QBCore Notification
-- Set to 'bulletin' for bulletin notification (https://github.com/Mobius1/bulletin)
Config.Notification = 'msk'

-- Only for MSK Notification
Config.NotifyTypes = {
    -- https://fontawesome.com/icons
    ['general'] = {icon = 'fa-solid fa-circle-info', color = '#f0ede8'},
    ['info'] = {icon = 'fa-solid fa-circle-info', color = '#75d6ff'},
    ['success'] = {icon = 'fa-solid fa-shield-check', color = '#00e676'},
    ['warning'] = {icon = 'fa-solid fa-triangle-exclamation', color = '#facc15'},
    ['error'] = {icon = 'fa-solid fa-circle-exclamation', color = '#f43f5e'},
}

Config.customNotification = function(title, message, typ, duration)
    -- Set Config.Notification = 'custom'
    -- Add your own clientside Notification here
end
----------------------------------------------------------------
-- Set to 'native' for FiveM Native AdvancedNotification
-- Set to 'custom' for Config.customAdvancedNotification()
-- Set to 'bulletin' for bulletin AdvancedNotification (https://github.com/Mobius1/bulletin)
Config.AdvancedNotification = 'native'

Config.customAdvancedNotification = function(text, title, subtitle, icon, flash, icontype)
    -- Set Config.AdvancedNotification = 'custom'
    -- Add your own clientside AdvancedNotification here
end
----------------------------------------------------------------
-- Set to 'msk' for MSK TextUI Notification
-- Set to 'native' for FiveM Native HelpNotification
-- Set to 'custom' for Config.customHelpNotification()
Config.HelpNotification = 'msk'

-- This will be called every frame -> Wait(0)
Config.customHelpNotification = function(text)
end
----------------------------------------------------------------
Config.ProgressColor = "#00e676" -- Default Color for ProgressBar (MSK Grün)
Config.TextUIColor = "#00e676" -- Default Color for TextUI (MSK Grün)
----------------------------------------------------------------
Config.LoggingTypes = {
    ['debug'] = '[^3DEBUG^0]',
    ['info'] = '[^4Info^0]',
    ['warn'] = '[^3Warning^0]^3',
    ['error'] = '[^1ERROR^0]^1',
}
----------------------------------------------------------------
-- If enabled it will display a 3D Text on the position the player disconnected
Config.DisconnectLogger = {
    enable = false, -- Set to true if you want to use this Feature

    console = {
        enable = false,
        text = "The player ^3%s^0 with the ^3ID %s^0 has left the server.\n^4Time:^0 %s\n^4Reason:^0 %s\n^4Identifier:^0\n    %s\n    %s\n    %s\n^4Coordinates:^0 %s"
    },

    discord = {
        enable = false, -- Set true to enable DiscordLogs // Add Webhook Link in modules/DisconnectLogger/server.lua
        color = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
        botName = "MSK Scripts",
        botAvatar = "https://i.imgur.com/PizJGsh.png",
        title = "Player Disconnected",
        text = "The player **%s** with the **ID %s** has left the server."
    }
}
----------------------------------------------------------------
-- For more Information go to: https://docu.msk-scripts.de/msk-core/functions/server/ban-system
Config.BanSystem = {
    enable = true, -- Set to true if you want to use this Feature

    discordLog = false, -- Set true to enable DiscordLogs // Add Webhook Link in modules/Ban/server.lua
    botColor = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
    botName = "MSK Scripts",
    botAvatar = "https://i.imgur.com/PizJGsh.png",

    commands = {
        enable = true,
        groups = {'superadmin', 'admin', 'god'},
        ban = 'banPlayer',
        unban = 'unbanPlayer'
    }
}
