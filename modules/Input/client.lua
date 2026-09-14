local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Input = {}

if IS_CORE then
    local isInputOpen = false
    local callback = nil

    -- Held apart from `callback` so that Close() can settle a waiting caller.
    -- Without it, closing the input without submitting (escape, the closeInput
    -- event, a resource stop) only cleared the callback and left the promise
    -- unresolved: a blocking MSK.Input(...) then waited forever and its thread
    -- was gone for the rest of the session.
    local pendingPromise = nil

    local function settle(value)
        local waiting = pendingPromise
        pendingPromise = nil

        if waiting then
            waiting:resolve(value)
        end
    end

    -- The old single-field input. Kept working, but deprecated in favour of
    -- Input.Dialog, see below.
    local function openLegacy(header, placeholder, field, cb)
        if isInputOpen then return end
        isInputOpen = true
        callback = cb
        if not callback then callback = field end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openInput",
            header = header,
            placeholder = placeholder,
            field = field and type(field) == 'boolean'
        })

        if not callback or callback and type(callback) == 'boolean' then
            local p = promise.new()
            pendingPromise = p

            callback = function(response)
                settle(response)
            end

            return Citizen.Await(p)
        end
    end

    -- One warning per resource, not per call: an input opened in a loop would
    -- otherwise flood the console.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" uses MSK.Input / MSK.OpenInput, which is deprecated and will be removed in a future version. Use MSK.Input.Dialog instead.'):format(resource))
    end

    ---@deprecated Use MSK.Input.Dialog
    function Input.Open(header, placeholder, field, cb)
        warnDeprecated(GetInvokingResource())
        return openLegacy(header, placeholder, field, cb)
    end
    MSK.OpenInput = Input.Open
    exports('Input', Input.Open)
    exports('OpenInput', Input.Open)

    function Input.Close()
        isInputOpen = false
        callback = nil

        -- Anyone still waiting gets nil, which reads as "cancelled".
        settle(nil)

        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeInput' })
    end
    MSK.CloseInput = Input.Close -- Backwards compatibility
    exports('CloseInput', Input.Close)
    RegisterNetEvent('msk_core:closeInput', Input.Close)

    -- The server already warned about the deprecated call on its side.
    MSK.Register('msk_core:input', function(source, header, placeholder, field)
        return openLegacy(header, placeholder, field)
    end)

    function Input.Active()
        return isInputOpen
    end
    exports('InputActive', Input.Active)

    RegisterNUICallback('submitInput', function(data)
        if data.input == '' then data.input = nil end
        if tonumber(data.input) then data.input = tonumber(data.input) end

        -- The NUI can submit after the input was closed from Lua, in which case
        -- there is no callback left to call. Calling it unchecked raised
        -- "attempt to call a nil value" out of a NUI callback.
        if callback then
            callback(data.input)
        end

        Input.Close()
    end)

    RegisterNUICallback('closeInput', function()
        Input.Close()
    end)

    --------------------------------------------------------------------------
    -- Input.Dialog
    --
    --   local values = MSK.Input.Dialog('Register vehicle', {
    --       { type = 'input', label = 'Plate', required = true, maxLength = 8 },
    --       { type = 'number', label = 'Price', min = 1, max = 100000 },
    --       { type = 'select', label = 'Garage', options = { { value = 'a', label = 'Pillbox' }, 'Sandy' } },
    --       { type = 'checkbox', label = 'Insured', id = 'insured' },
    --   }, { allowCancel = true, size = 'md' })
    --
    --   if values then print(values[1], values[2], values.insured) end
    --
    -- Returns nil when cancelled, otherwise the values by row number (and by
    -- id where a row has one). Empty optional fields are nil, so read the
    -- values by index instead of relying on #values. The field types and what
    -- they return are listed in modules/Input/shared.lua.
    --
    -- options: allowCancel (default true), size ('sm', 'md', 'lg'),
    --          labels { confirm, cancel }
    --------------------------------------------------------------------------
    local dialogOpen = false
    local dialogRows = nil
    local dialogPromise = nil

    local function settleDialog(values)
        dialogOpen = false
        dialogRows = nil
        SetNuiFocus(false, false)

        local waiting = dialogPromise
        dialogPromise = nil

        if waiting then
            waiting:resolve(values)
        end
    end

    ---@param header string
    ---@param rows (table|string)[]
    ---@param options? { allowCancel?: boolean, size?: 'sm'|'md'|'lg', labels?: { confirm?: string, cancel?: string } }
    ---@return table? values
    function Input.Dialog(header, rows, options)
        assert(type(header) == 'string', 'Parameter "header" has to be a string on function MSK.Input.Dialog')
        options = type(options) == 'table' and options or {}

        local normalized = InputDialog.NormalizeRows(rows)

        -- A second dialog replaces the first; whoever waited on it gets nil.
        if dialogOpen then
            settleDialog(nil)
        end

        dialogOpen = true
        dialogRows = normalized

        local p = promise.new()
        dialogPromise = p

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openInputDialog',
            header = header,
            rows = normalized,
            allowCancel = options.allowCancel ~= false,
            size = (options.size == 'sm' or options.size == 'lg') and options.size or 'md',
            labels = options.labels,
        })

        return Citizen.Await(p)
    end
    exports('InputDialog', Input.Dialog)

    ---Closes an open dialog. Whoever waits on it gets nil.
    function Input.CloseDialog()
        if not dialogOpen then return end

        SendNUIMessage({ action = 'closeInputDialog' })
        settleDialog(nil)
    end
    exports('CloseInputDialog', Input.CloseDialog)
    RegisterNetEvent('msk_core:closeInputDialog', Input.CloseDialog)

    ---@return boolean
    function Input.DialogActive()
        return dialogOpen
    end
    exports('InputDialogActive', Input.DialogActive)

    RegisterNUICallback('inputDialogSubmit', function(data, cb)
        cb('ok')
        if not dialogOpen then return end

        local values, err = InputDialog.Validate(dialogRows, data and data.values)

        -- The NUI validates before it submits, so this only fails when the
        -- two rule sets drifted apart. Treat it as a cancel and say why.
        if not values then
            MSK.Logging('warn', ('MSK.Input.Dialog rejected the submitted values: %s'):format(err))
        end

        settleDialog(values)
    end)

    RegisterNUICallback('inputDialogCancel', function(_, cb)
        cb('ok')
        if not dialogOpen then return end

        settleDialog(nil)
    end)

    MSK.Register('msk_core:inputDialog', function(source, header, rows, options)
        return Input.Dialog(header, rows, options)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        Input.Close()
        Input.CloseDialog()
    end)

    MSK.Input = setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Input
else
    function Input.Open(...) return exports.msk_core:Input(...) end
    function Input.Close() return exports.msk_core:CloseInput() end
    function Input.Active() return exports.msk_core:InputActive() end
    function Input.Dialog(header, rows, options) return exports.msk_core:InputDialog(header, rows, options) end
    function Input.CloseDialog() return exports.msk_core:CloseInputDialog() end
    function Input.DialogActive() return exports.msk_core:InputDialogActive() end

    return setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
end
