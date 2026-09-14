--------------------------------------------------------------------------------
-- MSK.Settings (client)
--
-- Per-player settings, stored on the player's machine (resource KVP), so they
-- survive reconnects and server restarts:
--
--   locale          ''  = server language, otherwise e.g. 'de'   (used by MSK.Locale)
--   notifyPosition  ''  = automatic (the script's position, otherwise top left),
--                   'top-left', 'top', 'top-right', 'center-left', 'center-right',
--                   'bottom-left', 'bottom', 'bottom-right'
--                   A position chosen here always wins over the one a script asks for.
--   notifySound     true / false
--
-- Players change them in a menu (command in Config.Settings). Scripts can read
-- them and react to changes:
--
--   MSK.Settings.Get('locale')
--   AddEventHandler('msk_core:settingChanged', function(key, value) ... end)
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Settings = {}

if IS_CORE then
    local KVP_KEY = 'msk_core:settings'
    local config = Config.Settings or {}

    local POSITIONS = {
        { value = '', label = 'Automatic' },
        { value = 'top-left', label = 'Top left' },
        { value = 'top', label = 'Top' },
        { value = 'top-right', label = 'Top right' },
        { value = 'center-left', label = 'Center left' },
        { value = 'center-right', label = 'Center right' },
        { value = 'bottom-left', label = 'Bottom left' },
        { value = 'bottom', label = 'Bottom' },
        { value = 'bottom-right', label = 'Bottom right' },
    }

    local DEFAULTS = {
        locale = '',
        notifyPosition = '',
        notifySound = true,
    }

    local function isPosition(value)
        for i = 1, #POSITIONS do
            if POSITIONS[i].value == value then return true end
        end
        return false
    end

    local VALIDATORS = {
        locale = function(value) return type(value) == 'string' end,
        notifyPosition = isPosition,
        notifySound = function(value) return type(value) == 'boolean' end,
    }

    local values = {}

    do
        local stored = {}
        local raw = GetResourceKvpString(KVP_KEY)

        if raw then
            local ok, decoded = pcall(json.decode, raw)
            if ok and type(decoded) == 'table' then stored = decoded end
        end

        -- Anything stored that is no longer valid (an old position name, a
        -- hand-edited value) falls back to the default instead of breaking.
        for key, default in pairs(DEFAULTS) do
            local value = stored[key]
            values[key] = (value ~= nil and VALIDATORS[key](value)) and value or default
        end
    end

    local function copy()
        local result = {}
        for key, value in pairs(values) do result[key] = value end
        return result
    end

    local function pushToNui()
        SendNUIMessage({
            action = 'settings',
            notifyPosition = values.notifyPosition,
            notifySound = values.notifySound,
        })
    end

    ---One setting, or a copy of all of them without `key`.
    ---@param key? string
    ---@return any
    function Settings.Get(key)
        if key == nil then return copy() end
        return values[key]
    end

    ---@return table
    function Settings.GetAll()
        return copy()
    end

    ---Changes a setting. Returns false when the value is not valid for it.
    ---@param key 'locale'|'notifyPosition'|'notifySound'
    ---@param value any
    ---@return boolean changed
    function Settings.Set(key, value)
        local validate = VALIDATORS[key]
        if not validate then
            error(('Unknown setting "%s"'):format(tostring(key)), 2)
        end

        if not validate(value) then return false end
        if values[key] == value then return true end

        values[key] = value
        SetResourceKvp(KVP_KEY, json.encode(values))

        pushToNui()
        TriggerEvent('msk_core:settingChanged', key, value)

        return true
    end

    --------------------------------------------------------------------------
    -- Menu
    --------------------------------------------------------------------------
    local MAIN_ID = 'msk_core:settings'
    local LOCALE_ID = 'msk_core:settings:locale'
    local POSITION_ID = 'msk_core:settings:position'

    local function localeLabel(value)
        local locales = config.locales or {}
        for i = 1, #locales do
            if locales[i].value == value then return locales[i].label end
        end
        return value == '' and 'Server language' or value
    end

    local function positionLabel(value)
        for i = 1, #POSITIONS do
            if POSITIONS[i].value == value then return POSITIONS[i].label end
        end
        return value
    end

    function Settings.Open()
        local locales = {}
        for i, entry in ipairs(config.locales or {}) do
            local selected = entry.value == values.locale
            locales[i] = {
                id = 'locale:' .. entry.value,
                title = entry.label,
                icon = selected and 'check' or 'language',
                iconColor = selected and '#00e676' or nil,
                onSelect = function()
                    Settings.Set('locale', entry.value)
                    Settings.Open()
                end,
            }
        end

        MSK.Context.Register(LOCALE_ID, { title = 'Language', menu = MAIN_ID, options = locales })

        local positions = {}
        for i, entry in ipairs(POSITIONS) do
            local selected = entry.value == values.notifyPosition
            positions[i] = {
                id = 'position:' .. entry.value,
                title = entry.label,
                icon = selected and 'check' or 'location-dot',
                iconColor = selected and '#00e676' or nil,
                onSelect = function()
                    Settings.Set('notifyPosition', entry.value)
                    MSK.Notification({
                        title = 'Settings',
                        message = entry.value == '' and 'Scripts decide where their notifications appear.' or 'Notifications will appear here from now on.',
                        type = 'success',
                    })
                    Settings.Open()
                end,
            }
        end

        MSK.Context.Register(POSITION_ID, { title = 'Notification position', menu = MAIN_ID, options = positions })

        MSK.Context.Show({
            id = MAIN_ID,
            title = 'Settings',
            options = {
                {
                    id = 'locale',
                    title = 'Language',
                    description = localeLabel(values.locale),
                    icon = 'language',
                    menu = LOCALE_ID,
                },
                {
                    id = 'notifyPosition',
                    title = 'Notification position',
                    description = positionLabel(values.notifyPosition),
                    icon = 'location-dot',
                    menu = POSITION_ID,
                },
                {
                    id = 'notifySound',
                    title = 'Notification sound',
                    description = values.notifySound and 'On' or 'Off',
                    icon = values.notifySound and 'volume-high' or 'volume-xmark',
                    onSelect = function()
                        Settings.Set('notifySound', not values.notifySound)
                        Settings.Open()
                    end,
                },
            },
        })
    end

    if config.enable ~= false then
        local command = config.command or 'mskSettings'

        RegisterCommand(command, function()
            Settings.Open()
        end, false)

        TriggerEvent('chat:addSuggestion', '/' .. command, 'Open your settings (language, notifications)')
    end

    -- The NUI asks for the settings once it has loaded. Sending them earlier
    -- would be lost, because the page does not exist yet.
    RegisterNUICallback('nuiReady', function(_, cb)
        cb('ok')
        pushToNui()
    end)

    exports('GetSetting', Settings.Get)
    exports('GetSettings', Settings.GetAll)
    exports('SetSetting', Settings.Set)
    exports('OpenSettings', Settings.Open)

    MSK.Settings = Settings
else
    function Settings.Get(key) return exports.msk_core:GetSetting(key) end
    function Settings.GetAll() return exports.msk_core:GetSettings() end
    function Settings.Set(key, value) return exports.msk_core:SetSetting(key, value) end
    function Settings.Open() return exports.msk_core:OpenSettings() end
end

return Settings
