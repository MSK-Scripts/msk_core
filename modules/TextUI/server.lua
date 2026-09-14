--------------------------------------------------------------------------------
-- MSK.TextUI (server)
--
--   MSK.TextUI.Show(playerId, { key = 'E', text = 'Open garage', icon = 'warehouse' })
--   MSK.TextUI.Hide(playerId)
--
-- The fields are described in modules/TextUI/client.lua. The old form
-- Show(playerId, key, text, color) still works, but is deprecated.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local TextUI = {}

if IS_CORE then
    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" calls MSK.TextUI.Show / ShowThread(playerId, key, text, color), which is deprecated and will be removed in a future version. Pass a table instead: MSK.TextUI.Show(playerId, { key = ..., text = ... })'):format(resource))
    end

    local function toTable(data, text, color)
        if type(data) == 'table' then return data end
        warnDeprecated(GetInvokingResource())
        return { key = data, text = text, color = color }
    end

    ---@param playerId number
    ---@param data table (the key, text, color form is deprecated)
    function TextUI.Show(playerId, data, text, color)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:textUiShow', playerId, toTable(data, text, color))
    end

    ---@param playerId number
    ---@param data table (the key, text, color form is deprecated)
    function TextUI.ShowThread(playerId, data, text, color)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:textUiShowThread', playerId, toTable(data, text, color))
    end

    function TextUI.Hide(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:textUiHide', playerId)
    end

    exports('ShowTextUI', TextUI.Show)
    exports('ShowTextUIThread', TextUI.ShowThread)
    exports('HideTextUI', TextUI.Hide)

    MSK.TextUI = setmetatable(TextUI, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.TextUI
else
    function TextUI.Show(...) return exports.msk_core:ShowTextUI(...) end
    function TextUI.ShowThread(...) return exports.msk_core:ShowTextUIThread(...) end
    function TextUI.Hide(...) return exports.msk_core:HideTextUI(...) end

    return setmetatable(TextUI, {
        __call = function(self, ...) return self.Show(...) end
    })
end
