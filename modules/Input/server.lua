local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Input = {}

if IS_CORE then
    function Input.Open(playerId, header, placeholder, field)
        if not playerId or playerId <= 0 then return end
        return MSK.Trigger('msk_core:input', playerId, header, placeholder, field)
    end
    exports('Input', Input.Open)
    exports('OpenInput', Input.Open)

    function Input.Close(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:closeInput', playerId)
    end
    MSK.CloseInput = Input.Close
    exports('CloseInput', Input.Close)

    MSK.Input = setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Input
else
    function Input.Open(...) return exports.msk_core:Input(...) end
    function Input.Close(...) return exports.msk_core:CloseInput(...) end

    return setmetatable(Input, {
        __call = function(self, ...) return self.Open(...) end
    })
end
