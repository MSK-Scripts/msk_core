if Config.Debug then
    print(('[^2%s^0] [^4Info^0] Boot (client) completed — framework: ^3%s^0, inventory: ^3%s^0'):format(
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
exports('TriggerCallback', Callback.TriggerCallback)

-- Also provide on the core MSK table, so core code (e.g. HasItem,
-- later Input/Numpad) can use MSK.Register/Trigger directly.
MSK.Register = Callback.Register
MSK.Trigger = Callback.Trigger
MSK.TriggerCallback = Callback.TriggerCallback

--------------------------------------------------------------------------------
-- Player — core singleton: the 100ms thread + msk_core:onPlayer run
-- here EXACTLY ONCE. Consumers get the local view via @msk_core/import.lua.
--------------------------------------------------------------------------------
local PlayerModule = MSK.LoadModule('Player')
if not PlayerModule then error('msk_core: Player module could not be loaded.', 0) end
MSK.Player = PlayerModule

--------------------------------------------------------------------------------
-- Client module exports: Request + Points (lazy-in-core via registry)
--------------------------------------------------------------------------------
-- Request
MSK.RegisterExport('RequestStreaming',     'Request', 'Streaming')
MSK.RegisterExport('RequestScaleformMovie', 'Request', 'ScaleformMovie')
MSK.RegisterExport('RequestAnimDict',      'Request', 'AnimDict')
MSK.RegisterExport('RequestModel',         'Request', 'Model')
MSK.RegisterExport('RequestAnimSet',       'Request', 'AnimSet')
MSK.RegisterExport('RequestPtfxAsset',     'Request', 'PtfxAsset')
MSK.RegisterExport('RequestTextureDict',   'Request', 'TextureDict')
MSK.RegisterExport('RequestRaycast',       'Request', 'Raycast')
-- Points
MSK.RegisterExport('AddPoint',        'Points', 'Add')
MSK.RegisterExport('RemovePoint',     'Points', 'Remove')
MSK.RegisterExport('GetAllPoints',    'Points', 'GetAllPoints')
MSK.RegisterExport('GetClosestPoint', 'Points', 'GetClosestPoint')

--------------------------------------------------------------------------------
-- Scaleform — NetEvent handlers only in the core -> load eager.
--------------------------------------------------------------------------------
MSK.Scaleform = MSK.LoadModule('Scaleform')

--------------------------------------------------------------------------------
-- Entities + Vehicle — core singletons (death detection, enter/exit thread).
-- Order: Entities BEFORE Vehicle (Vehicle uses MSK.GetClosestEntity).
--------------------------------------------------------------------------------
MSK.LoadModule('Entities')
MSK.LoadModule('Vehicle')

--------------------------------------------------------------------------------
-- ACE -> Command -> Coords. Order matters:
-- Command uses MSK.IsAceAllowed (ACE); Coords uses MSK.RegisterCommand (Command).
--------------------------------------------------------------------------------
MSK.LoadModule('Ace')
MSK.LoadModule('Command')
MSK.LoadModule('Coords')

--------------------------------------------------------------------------------
-- UI / NUI) — NUI handlers/callbacks + NetEvents only in the core -> eager.
--------------------------------------------------------------------------------
MSK.LoadModule('Notify')
MSK.LoadModule('Progress')
MSK.LoadModule('TextUI')
MSK.LoadModule('Input')
MSK.LoadModule('Numpad')
MSK.LoadModule('Context')
MSK.LoadModule('Menu')

--------------------------------------------------------------------------------
-- World + Disconnect-Logger — eager. World sets its own MSK.*
-- functions + exports; the Disconnect-Logger registers the 3D display.
--------------------------------------------------------------------------------
MSK.LoadModule('World')
MSK.LoadModule('DisconnectLogger')

--------------------------------------------------------------------------------
-- MarkLoaded — the core is the last to load, so mark the resource as loaded.
--------------------------------------------------------------------------------
MSK.MarkLoaded()
