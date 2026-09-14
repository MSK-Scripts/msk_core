--------------------------------------------------------------------------------
-- MSK.TextUI (client)
--
--   MSK.TextUI.Show({
--       key = 'E',                    -- false = no key box
--       text = 'Open ~g~garage~s~',
--       color = '#00e676',            -- color of the key box
--       icon = 'warehouse', iconColor = '#00e676', iconAnimation = 'bounce',
--       position = 'bottom-center',   -- bottom-center, top-center, left-center, right-center
--   })
--   MSK.TextUI.Hide()
--
-- Calling Show again while the TextUI is open updates it. Calling it with the
-- same data again does nothing, so it is safe inside a loop.
--
-- MSK.TextUI.ShowThread({ ... }) is meant for calls every frame: it hides the
-- TextUI by itself about 100 ms after the last call.
--
-- The TextUI belongs to the resource that showed it and is hidden when that
-- resource stops.
--
-- The old forms Show(key, text, color) and ShowThread(key, text, color) still
-- work, but are deprecated.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local TextUI = {}

if IS_CORE then
    local POSITIONS = {
        ['bottom-center'] = true, ['top-center'] = true,
        ['left-center'] = true, ['right-center'] = true,
    }

    local ANIMATIONS = {
        spin = true, spinPulse = true, spinReverse = true, beat = true, beatFade = true,
        bounce = true, fade = true, flip = true, shake = true,
    }

    local current = nil          -- normalised data of the open TextUI
    local owner = nil            -- resource that showed it
    local viaThread = false      -- shown through ShowThread (and not replaced by a plain Show since)
    local threadRunning = false
    local lastThreadCall = 0

    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" calls MSK.TextUI.Show / ShowThread(key, text, color), which is deprecated and will be removed in a future version. Pass a table instead: MSK.TextUI.Show({ key = ..., text = ... })'):format(resource))
    end

    local function normalize(input)
        -- Written out instead of `x == false and false or ...`: that idiom
        -- turns false into the fallback, exactly the value that must survive.
        local key = input.key
        if key ~= false then
            key = tostring(key or 'E')
        end

        return {
            key = key,
            text = input.text ~= nil and tostring(input.text) or '',
            color = type(input.color) == 'string' and input.color or Config.TextUIColor,
            icon = type(input.icon) == 'string' and input.icon or nil,
            iconColor = type(input.iconColor) == 'string' and input.iconColor or nil,
            iconAnimation = ANIMATIONS[input.iconAnimation] and input.iconAnimation or nil,
            position = POSITIONS[input.position] and input.position or 'bottom-center',
        }
    end

    local function sameAs(a, b)
        return a.key == b.key and a.text == b.text and a.color == b.color
            and a.icon == b.icon and a.iconColor == b.iconColor
            and a.iconAnimation == b.iconAnimation and a.position == b.position
    end

    local function display(data, resource)
        owner = resource or 'msk_core'

        -- Unchanged data sends nothing, so a Show inside a loop does not flood
        -- the NUI with identical messages.
        if current and sameAs(current, data) then return end

        current = data

        SendNUIMessage({
            action = 'textUI',
            show = true,
            key = data.key,
            text = data.text,
            color = data.color,
            icon = data.icon,
            iconColor = data.iconColor,
            iconAnimation = data.iconAnimation,
            position = data.position,
        })
    end

    local function toTable(data, text, color, resource, warn)
        if type(data) == 'table' then return data end
        if warn then warnDeprecated(resource) end
        return { key = data, text = text, color = color }
    end

    local function showThreaded(data, resource)
        viaThread = true
        display(data, resource)
        lastThreadCall = GetGameTimer()

        if threadRunning then return end
        threadRunning = true

        CreateThread(function()
            while GetGameTimer() - lastThreadCall <= 100 do
                Wait(50)
            end

            threadRunning = false

            -- A plain Show took over in the meantime and owns the TextUI now.
            if viaThread then
                TextUI.Hide()
            end
        end)
    end

    ---@param data table (the key, text, color form is deprecated)
    function TextUI.Show(data, text, color)
        local resource = GetInvokingResource()

        viaThread = false
        display(normalize(toTable(data, text, color, resource, true)), resource)
    end

    ---@param data table (the key, text, color form is deprecated)
    function TextUI.ShowThread(data, text, color)
        local resource = GetInvokingResource()
        showThreaded(normalize(toTable(data, text, color, resource, true)), resource)
    end

    function TextUI.Hide()
        if not current then return end

        current = nil
        owner = nil
        viaThread = false

        SendNUIMessage({ action = 'textUI', show = false })
    end

    ---@return boolean open, table? data
    function TextUI.Active()
        if not current then return false end

        local copy = {}
        for key, value in pairs(current) do copy[key] = value end
        return true, copy
    end

    exports('ShowTextUI', TextUI.Show)
    exports('ShowTextUIThread', TextUI.ShowThread)
    exports('HideTextUI', TextUI.Hide)
    exports('TextUIActive', TextUI.Active)

    -- Server -> client. The server warns about the deprecated form on its own
    -- side, so these handlers do not warn again.
    RegisterNetEvent("msk_core:textUiShow", function(data, text, color)
        viaThread = false
        display(normalize(toTable(data, text, color, nil, false)), nil)
    end)

    RegisterNetEvent("msk_core:textUiShowThread", function(data, text, color)
        showThreaded(normalize(toTable(data, text, color, nil, false)), nil)
    end)

    RegisterNetEvent("msk_core:textUiHide", TextUI.Hide)

    AddEventHandler('onResourceStop', function(resource)
        -- The resource that showed the TextUI stopped: nobody is left to hide
        -- it, so it would stay on screen until the next restart.
        if resource == 'msk_core' or (owner and resource == owner) then
            TextUI.Hide()
        end
    end)

    MSK.TextUI = setmetatable(TextUI, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.TextUI
else
    function TextUI.Show(...) return exports.msk_core:ShowTextUI(...) end
    function TextUI.ShowThread(...) return exports.msk_core:ShowTextUIThread(...) end
    function TextUI.Hide() return exports.msk_core:HideTextUI() end
    function TextUI.Active() return exports.msk_core:TextUIActive() end

    return setmetatable(TextUI, {
        __call = function(self, ...) return self.Show(...) end
    })
end
