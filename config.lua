Config = {}
----------------------------------------------------------------
Config.Debug = false
Config.VersionChecker = true
----------------------------------------------------------------
-- Only Required for MSK.RegisterCommand // View Wiki for more Information about that!
Config.Framework = 'esx' -- Set to 'standalone', 'esx' or 'qbcore'
----------------------------------------------------------------
Config.showCoords = {
    enable = true,
    command = 'coords',
    groups = {'superadmin', 'admin'}
}
----------------------------------------------------------------
-- Set to 'native' for FiveM Native Notification
-- Set to 'msk' for NUI Notification
-- Set to 'okok' for OKOK Notification
Config.Notification = 'msk'

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
        enable = true,
        text = "Der Spieler ^3%s^0 mit der ^3ID %s^0 hat den Server verlassen.\n^4Uhrzeit:^0 %s\n^4Grund:^0 %s\n^4Identifier:^0\n    %s\n    %s\n    %s\n^4Koordinaten:^0 %s"
    },
    discord = {
        -- Webhook in sv_anticombatlog.lua
        enable = true,
        color = "6205745", -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
        botName = "MSK Scripts",
        botAvatar = "https://i.imgur.com/PizJGsh.png",
        title = "Player Disconnected",
        text = "Der Spieler **%s** mit der **ID %s** hat den Server verlassen."
    }
}