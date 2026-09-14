--------------------------------------------------------------------------------
-- MSK.Alert (client)
--
-- A modal dialog that waits for the player's answer.
--
--   local answer = MSK.Alert.Show({
--       header = 'Sell vehicle',
--       content = 'Do you really want to sell your ~g~Sultan~s~ for $12.000?',
--       labels = { confirm = 'Sell', cancel = 'Keep' },
--   })
--
--   if answer == 'confirm' then ... end
--
-- Returns 'confirm' or 'cancel', 'timeout' when `timeout` ran out, and nil when
-- the dialog was closed from code.
-- Fields: header, content (line breaks and ~color~ codes work), size ('sm',
-- 'md', 'lg'), centered (center the text), cancel (false hides the cancel
-- button), labels { confirm, cancel }, timeout (milliseconds).
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Alert = {}

if IS_CORE then
    local isOpen = false
    local pendingPromise = nil

    -- Counts dialogs, so a timeout only closes the dialog it was started for.
    local generation = 0

    local function settle(result)
        isOpen = false
        SetNuiFocus(false, false)

        local waiting = pendingPromise
        pendingPromise = nil

        if waiting then
            waiting:resolve(result)
        end
    end

    ---@param data { header?: string, content: string, size?: 'sm'|'md'|'lg', centered?: boolean, cancel?: boolean, labels?: { confirm?: string, cancel?: string }, timeout?: number }
    ---@return 'confirm'|'cancel'|'timeout'|nil
    function Alert.Show(data)
        assert(type(data) == 'table', 'Parameter "data" has to be a table on function MSK.Alert.Show')
        assert(data.content ~= nil or data.header ~= nil, 'Field "content" or "header" is required on function MSK.Alert.Show')

        -- A second dialog replaces the first; whoever waited on it gets nil.
        if isOpen then settle(nil) end

        isOpen = true
        generation = generation + 1

        local current = generation
        local timeout = tonumber(data.timeout)

        if timeout and timeout > 0 then
            SetTimeout(timeout, function()
                if isOpen and generation == current then
                    SendNUIMessage({ action = 'closeAlert' })
                    settle('timeout')
                end
            end)
        end

        local p = promise.new()
        pendingPromise = p

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openAlert',
            header = data.header,
            content = data.content and tostring(data.content) or '',
            size = data.size or 'md',
            centered = data.centered == true,
            cancel = data.cancel ~= false,
            labels = data.labels,
        })

        return Citizen.Await(p)
    end

    function Alert.Close()
        if not isOpen then return end

        SendNUIMessage({ action = 'closeAlert' })
        settle(nil)
    end

    ---@return boolean
    function Alert.Active()
        return isOpen
    end

    RegisterNUICallback('alertResult', function(data, cb)
        cb('ok')
        if not isOpen then return end

        settle(data and data.result == 'confirm' and 'confirm' or 'cancel')
    end)

    MSK.Register('msk_core:alert', function(source, data)
        return Alert.Show(data)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= 'msk_core' then return end
        Alert.Close()
    end)

    exports('AlertDialog', Alert.Show)
    exports('CloseAlertDialog', Alert.Close)
    exports('AlertActive', Alert.Active)

    MSK.Alert = Alert
else
    function Alert.Show(data) return exports.msk_core:AlertDialog(data) end
    function Alert.Close() return exports.msk_core:CloseAlertDialog() end
    function Alert.Active() return exports.msk_core:AlertActive() end
end

return setmetatable(Alert, {
    __call = function(_, data) return Alert.Show(data) end
})
