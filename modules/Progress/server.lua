--------------------------------------------------------------------------------
-- MSK.Progress (server)
--
--   local done = MSK.Progress(playerId, { duration = 5000, text = 'Repairing', canCancel = true })
--   local done = MSK.Progress.Circle(playerId, { duration = 3000, text = 'Eating' })
--
-- The table form waits until the progress ends on the client and returns true
-- when it ran out, false otherwise. The fields are described in
-- modules/Progress/client.lua.
--
-- The result is reported by the client. Good enough for gameplay, but check on
-- the server whether the action was plausible before you hand out money or
-- items for it.
--
-- The old form MSK.Progress(playerId, duration, text, color) still works, does
-- not wait, and is deprecated.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Progress = {}

if IS_CORE then
    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" calls MSK.Progress(playerId, duration, text, color), which is deprecated and will be removed in a future version. Pass a table instead: MSK.Progress(playerId, { duration = ..., text = ... }). The table form waits and returns true or false.'):format(resource))
    end

    local function start(playerId, data, text, color, style)
        if not playerId or playerId <= 0 then return end

        if type(data) ~= 'table' then
            warnDeprecated(GetInvokingResource())
            TriggerClientEvent(style == 'circle' and 'msk_core:progressCircle' or 'msk_core:progressbar', playerId, data, text, color)
            return
        end

        -- TriggerAwait, not Trigger: a progress easily runs longer than the
        -- 5 second limit of a normal callback.
        return MSK.TriggerAwait('msk_core:progress', playerId, nil, data, style) == true
    end

    ---@param playerId number
    ---@param data table (the number form is deprecated)
    ---@return boolean? finished
    function Progress.Start(playerId, data, text, color)
        return start(playerId, data, text, color, type(data) == 'table' and data.type == 'circle' and 'circle' or nil)
    end

    ---@param playerId number
    ---@param data table (the number form is deprecated)
    ---@return boolean? finished
    function Progress.Circle(playerId, data, text, color)
        return start(playerId, data, text, color, 'circle')
    end

    function Progress.Stop(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:progressbarStop', playerId)
    end

    MSK.Progressbar = Progress.Start -- Backwards compatibility
    exports('Progressbar', Progress.Start)
    exports('ProgressCircle', Progress.Circle)
    exports('ProgressStop', Progress.Stop)

    MSK.Progress = setmetatable(Progress, {
        __call = function(self, ...) return self.Start(...) end
    })
    return MSK.Progress
else
    function Progress.Start(...) return exports.msk_core:Progressbar(...) end
    function Progress.Circle(...) return exports.msk_core:ProgressCircle(...) end
    function Progress.Stop(...) return exports.msk_core:ProgressStop(...) end

    return setmetatable(Progress, {
        __call = function(self, ...) return self.Start(...) end
    })
end
