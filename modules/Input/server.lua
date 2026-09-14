local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Input = {}

if IS_CORE then
    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" uses MSK.Input / MSK.OpenInput, which is deprecated and will be removed in a future version. Use MSK.Input.Dialog instead.'):format(resource))
    end

    ---@deprecated Use MSK.Input.Dialog
    function Input.Open(playerId, header, placeholder, field)
        warnDeprecated(GetInvokingResource())

        if not playerId or playerId <= 0 then return end

        -- TriggerAwait instead of Trigger: typing takes longer than the 5 second
        -- limit of a normal callback, which used to end every input with nil.
        return MSK.TriggerAwait('msk_core:input', playerId, nil, header, placeholder, field)
    end
    exports('Input', Input.Open)
    exports('OpenInput', Input.Open)

    function Input.Close(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:closeInput', playerId)
    end
    MSK.CloseInput = Input.Close
    exports('CloseInput', Input.Close)

    ---Opens an input dialog on a client and waits for the values, see
    ---modules/Input/client.lua. The client's answer is validated here again
    ---against the same rows, so a modified client cannot slip past required
    ---fields, ranges or select options.
    ---@param playerId number
    ---@param header string
    ---@param rows (table|string)[]
    ---@param options? table
    ---@return table? values
    function Input.Dialog(playerId, header, rows, options)
        assert(tonumber(playerId) and tonumber(playerId) > 0, 'Parameter "playerId" has to be a player id on function MSK.Input.Dialog')
        assert(type(header) == 'string', 'Parameter "header" has to be a string on function MSK.Input.Dialog')

        local normalized = InputDialog.NormalizeRows(rows)
        local values = MSK.TriggerAwait('msk_core:inputDialog', playerId, nil, header, rows, options)

        if values == nil then return nil end

        local cleaned, err = InputDialog.Validate(normalized, values)

        if not cleaned then
            MSK.Logging('warn', ('MSK.Input.Dialog: player %s sent values that do not match the dialog (%s)'):format(playerId, err))
            return nil
        end

        return cleaned
    end
    exports('InputDialog', Input.Dialog)

    ---@param playerId number
    function Input.CloseDialog(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:closeInputDialog', playerId)
    end
    exports('CloseInputDialog', Input.CloseDialog)

    MSK.Input = setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Input
else
    function Input.Open(...) return exports.msk_core:Input(...) end
    function Input.Close(...) return exports.msk_core:CloseInput(...) end
    function Input.Dialog(...) return exports.msk_core:InputDialog(...) end
    function Input.CloseDialog(...) return exports.msk_core:CloseInputDialog(...) end

    return setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
end
