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
-- NUI error reporting — each component in the NUI is wrapped in its own error
-- boundary (web/src/components/ErrorBoundary.tsx). When one of them crashes it
-- reports here, so the failure shows up in the client console instead of the
-- component just silently disappearing.
-- This file only ever runs inside msk_core, so no IS_CORE guard is needed.
-- Deliberately not gated behind Config.Debug: a dead UI component is an error.
--------------------------------------------------------------------------------
RegisterNUICallback('nuiError', function(data, cb)
    local component = data and data.component or 'unknown'
    local message = data and data.message or 'no message'

    MSK.Logging('error', ('NUI component "%s" crashed: %s'):format(component, message))

    if data and type(data.stack) == 'string' and data.stack ~= '' then
        print(('[^2msk_core^0] %s'):format(data.stack))
    end

    if data and data.final then
        MSK.Logging('warn', ('NUI component "%s" is in a crash loop and stays hidden until the resource restarts.'):format(component))
    end

    cb('ok')
end)

--------------------------------------------------------------------------------
-- MarkLoaded — the core is the last to load, so mark the resource as loaded.
--------------------------------------------------------------------------------
MSK.MarkLoaded()
