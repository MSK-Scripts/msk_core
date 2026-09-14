-- msk_core owns the server -> client notification transport. The RegisterNetEvent
-- listeners at the bottom of this file must exist EXACTLY ONCE per client and
-- belong to msk_core alone. A consumer that eager-loads this module still gets
-- every display function (MSK.Notification, MSK.HelpNotification, …) so it can
-- show notifications locally, but it must NOT register a second set of listeners:
-- otherwise a server-sent notification fires in msk_core AND in each eager-loading
-- consumer, and the player sees it twice (or N+1 times). Same class of bug as the
-- Callback module.
local IS_CORE = GetCurrentResourceName() == 'msk_core'

--------------------------------------------------------------------------------
-- MSK.Notification
--
--   MSK.Notification({
--       id = 'garage_full',          -- a visible notification with this id is updated instead of stacked
--       title = 'Garage',            -- optional, without a title the notification is compact
--       message = 'Your garage is ~r~full~s~.',
--       type = 'error',              -- general, info, success, warning, error (Config.NotifyTypes)
--       duration = 6000,
--       icon = 'warehouse',          -- overrides the icon of the type
--       iconColor = '#f43f5e',
--       iconAnimation = 'shake',     -- spin, spinPulse, spinReverse, beat, beatFade, bounce, fade, flip, shake
--       position = 'top-right',      -- only used while the player's setting is "Automatic"
--       showDuration = false,        -- hides the progress bar
--       sound = true,                -- false = silent, or { bank =, set =, name = } for a GTA sound
--   })
--
-- The old form MSK.Notification(title, message, type, duration) still works,
-- but is deprecated and logs a warning once per resource.
--
-- Everything beyond title, message, type and duration only applies to the MSK
-- UI. The external adapters (okok, qb-core, bulletin, native, custom) get what
-- they understand.
--------------------------------------------------------------------------------
local POSITIONS = {
    ['top-left'] = true, ['top'] = true, ['top-right'] = true,
    ['center-left'] = true, ['center-right'] = true,
    ['bottom-left'] = true, ['bottom'] = true, ['bottom-right'] = true,
}

local ANIMATIONS = {
    spin = true, spinPulse = true, spinReverse = true, beat = true, beatFade = true,
    bounce = true, fade = true, flip = true, shake = true,
}

-- One warning per resource, not per call.
local warnedResources = {}

local function warnDeprecated(resource)
    resource = resource or 'msk_core'
    if warnedResources[resource] then return end
    warnedResources[resource] = true

    MSK.Logging('warn', ('Resource "%s" calls MSK.Notification(title, message, type, duration), which is deprecated and will be removed in a future version. Pass a table instead: MSK.Notification({ title = ..., message = ..., type = ... })'):format(resource))
end

local function toData(titleOrData, message, typ, duration)
    if type(titleOrData) == 'table' then return titleOrData end
    return { title = titleOrData, message = message, type = typ, duration = duration }
end

local function soundEnabled()
    return not (MSK.Settings and MSK.Settings.Get('notifySound') == false)
end

local function playGameSound(sound)
    CreateThread(function()
        local bank = sound.bank

        if bank and not pcall(MSK.Request.AudioBank, bank) then
            return
        end

        PlaySoundFrontend(-1, sound.name, sound.set, true)

        if bank then
            Wait(5000)
            ReleaseNamedScriptAudioBank(bank)
        end
    end)
end

local function show(data)
    local title = data.title
    local message = data.message or data.description or ''
    local typ = data.type or 'info'
    local duration = tonumber(data.duration) or 5000

    if Config.Notification == 'native' then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    elseif Config.Notification == 'okok' then
        exports.okokNotify:Alert(title, message, duration, typ)
    elseif Config.Notification == 'qb-core' then
        -- 'qb-core' means "use the framework's own notification". On Qbox that
        -- is the qbx_core export, and QBCore is not defined there at all, so
        -- calling QBCore.Functions.Notify raised an error instead of notifying.
        if MSK.Bridge.Framework.Type == 'Qbox' then
            QBX:Notify(message, typ, duration)
        else
            QBCore.Functions.Notify(message, typ, duration)
        end
    elseif Config.Notification == 'bulletin' then
        exports.bulletin:Send({
            message = message,
            timeout = duration,
            theme = typ
        })
    elseif Config.Notification == 'custom' then
        Config.customNotification(title, message, typ, duration, data)
    else
        -- A GTA sound replaces the NUI sound; the player's sound setting
        -- silences both.
        local nuiSound = data.sound ~= false

        if type(data.sound) == 'table' and data.sound.name and data.sound.set then
            nuiSound = false
            if soundEnabled() then playGameSound(data.sound) end
        end

        SendNUIMessage({
            action = 'notify',
            id = data.id ~= nil and tostring(data.id) or nil,
            title = title,
            message = message,
            type = Config.NotifyTypes[typ] or {icon = 'fas fa-info-circle', color = '#75D6FF'},
            time = duration,
            icon = type(data.icon) == 'string' and data.icon or nil,
            iconColor = type(data.iconColor) == 'string' and data.iconColor or nil,
            iconAnimation = ANIMATIONS[data.iconAnimation] and data.iconAnimation or nil,
            position = POSITIONS[data.position] and data.position or nil,
            showDuration = data.showDuration ~= false,
            sound = nuiSound,
        })
    end
end

---@param titleOrData table|string a table with the fields above (the string form is deprecated)
function MSK.Notification(titleOrData, message, typ, duration)
    -- Only msk_core has the NUI page. A consumer that eager-loaded this module
    -- would send its SendNUIMessage into a page that does not exist.
    if not IS_CORE then
        return exports.msk_core:Notification(titleOrData, message, typ, duration)
    end

    if type(titleOrData) ~= 'table' then
        warnDeprecated(GetInvokingResource())
    end

    return show(toData(titleOrData, message, typ, duration))
end
MSK.Notify = MSK.Notification
exports('Notification', MSK.Notification)
exports('Notify', MSK.Notification)

function MSK.HelpNotification(text, key)
    if Config.HelpNotification == 'native' then
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayHelp(0, false, true, -1)
    elseif Config.HelpNotification == 'custom' then
        Config.customHelpNotification(text)
    else
        MSK.TextUI.ShowThread({ key = key, text = text })
    end
end
MSK.HelpNotify = MSK.HelpNotification
exports('HelpNotification', MSK.HelpNotification)
exports('HelpNotify', MSK.HelpNotification)

function MSK.AdvancedNotification(text, title, subtitle, icon, flash, icontype)
    -- `== nil`, not `not flash`: passing false explicitly turned flashing back
    -- on, so the parameter could be set but never cleared.
    if flash == nil then flash = true end
    if not icontype then icontype = 1 end
    if not icon then icon = 'CHAR_HUMANDEFAULT' end

    if Config.AdvancedNotification == 'bulletin' and GetResourceState('bulletin') == 'started' then
        exports.bulletin:SendAdvanced({
            message = text,
            title = title,
            subject = subtitle,
            icon = icon,
            timeout = 5000
        })
    elseif Config.AdvancedNotification == 'custom' then
        Config.customAdvancedNotification(text, title, subtitle, icon, flash, icontype)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandThefeedPostMessagetext(icon, icon, flash, icontype, title, subtitle)
        EndTextCommandThefeedPostTicker(false, true)
    end
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)
exports('AdvancedNotify', MSK.AdvancedNotification)

function MSK.Subtitle(text, duration)
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration or 8000, true)
end
exports('Subtitle', MSK.Subtitle)

function MSK.Spinner(text, typ, duration)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandBusyspinnerOn(typ or 4) -- 4 = orange, 5 = white

    MSK.Timeout.Set(duration or 5000, function()
        BusyspinnerOff()
    end)
end
exports('Spinner', MSK.Spinner)

function MSK.Draw3DText(coords, text, size, font)
    coords = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(coords - camCoords)

    if not size then size = 1 end
    if not font then font = 0 end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, scale * 0.5)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end
exports('Draw3DText', MSK.Draw3DText)

function MSK.DrawGenericText(text, outline, font, size, color, position)
    if not font then font = 0 end
    if not size then size = 0.34 end
    if not color then color = {r = 255, g = 255, b = 255, a = 255} end
    if not position then position = {width = 0.50, height = 0.90} end

    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextFont(font)
    SetTextScale(size, size)
    SetTextWrap(0.0, 1.0)
    SetTextCentre(true)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 205)
    if outline then SetTextOutline() end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(position.width, position.height)
end
exports('DrawGenericText', MSK.DrawGenericText)

-- Server -> client transport. Core-owned singletons (see the note at the top):
-- only msk_core may listen here, so notifications are not duplicated across
-- consumers that eager-load this module.
if IS_CORE then
    -- The server already warned about the old argument form on its side, so
    -- the transport normalises without warning again.
    RegisterNetEvent("msk_core:notification", function(titleOrData, message, typ, duration)
        show(toData(titleOrData, message, typ, duration))
    end)
    RegisterNetEvent("msk_core:helpNotification", MSK.HelpNotification)
    RegisterNetEvent("msk_core:advancedNotification", MSK.AdvancedNotification)
    RegisterNetEvent("msk_core:subtitle", MSK.Subtitle)
    RegisterNetEvent("msk_core:spinner", MSK.Spinner)
    RegisterNetEvent("msk_core:draw3DText", MSK.Draw3DText)
    RegisterNetEvent("msk_core:drawGenericText", MSK.DrawGenericText)
end

return true
