if Config.Debug then
    print(('[^2%s^0] [^4Info^0] Boot (server) completed — framework: ^3%s^0, inventory: ^3%s^0'):format(
        GetCurrentResourceName(),
        MSK.Bridge.Framework.Type or '??',
        MSK.Bridge.Inventory or '??'
    ))
end

--------------------------------------------------------------------------------
-- Callback system — Loaded EAGER into the core, so the NetEvent handlers
-- exist from start.
-- Consumers use the local view via @msk_core/import.lua
--------------------------------------------------------------------------------
local Callback = MSK.LoadModule('Callback')
if not Callback then error('msk_core: Callback module could not be loaded.', 0) end

exports('Register', Callback.Register)
exports('Trigger', Callback.Trigger)
exports('RegisterCallback', Callback.Register)       -- Backwards compatibility (server only)
exports('RegisterServerCallback', Callback.Register) -- Backwards compatibility (server only)

-- Also provide on the core MSK table (for core code like HasItem, ACE …).
MSK.Register = Callback.Register
MSK.Trigger = Callback.Trigger

--------------------------------------------------------------------------------
-- Player — core: mirrored player table, msk_core:onPlayer handler,
-- msk_core:player callback and the wrappers (GetPlayerFromId, …). ONCE in the core.
--------------------------------------------------------------------------------
local PlayerModule = MSK.LoadModule('Player')
if not PlayerModule then error('msk_core: Player module could not be loaded.', 0) end
MSK.Player = PlayerModule

--------------------------------------------------------------------------------
-- Entities + Vehicle. Entities BEFORE Vehicle (Vehicle uses
-- MSK.GetClosestEntity). Vehicle functions are reachable via the export proxy.
--------------------------------------------------------------------------------
MSK.LoadModule('Entities')
MSK.LoadModule('Vehicle')

--------------------------------------------------------------------------------
-- ACE -> Command -> Coords. Order matters:
-- Command uses MSK.IsAceAllowed (ACE); Coords commands use MSK.RegisterCommand.
--------------------------------------------------------------------------------
MSK.LoadModule('Ace')
MSK.LoadModule('Command')
MSK.LoadModule('Coords')

--------------------------------------------------------------------------------
-- UI / NUI. Notify sets MSK.Notification (used by Command).
--------------------------------------------------------------------------------
MSK.LoadModule('Notify')
MSK.LoadModule('Progress')
MSK.LoadModule('TextUI')
MSK.LoadModule('Input')
MSK.LoadModule('Numpad')

--------------------------------------------------------------------------------
-- World — eager (sets MSK.* + exports itself; MSK.AddWebhook from Ban/Disc).
--------------------------------------------------------------------------------
MSK.LoadModule('World')

--------------------------------------------------------------------------------
-- Optional features — toggleable via Config. Order: World BEFORE
-- Ban/Disconnect-Logger (they use MSK.AddWebhook); Command is already loaded.
--------------------------------------------------------------------------------
MSK.LoadModule('Cron')
MSK.LoadModule('Ban')
MSK.LoadModule('DisconnectLogger')
MSK.LoadModule('Check')

--------------------------------------------------------------------------------
-- Banking support modules — eager so their exports exist for consumers
-- (Society = company account money, Offline = offline framework-bank money).
-- Both run in the core where ESX/QBCore + MySQL are available.
--------------------------------------------------------------------------------
MSK.LoadModule('Society')
MSK.LoadModule('Offline')

--------------------------------------------------------------------------------
-- MarkLoaded — the core is the last to load, so mark the resource as loaded.
--------------------------------------------------------------------------------
MSK.MarkLoaded()
