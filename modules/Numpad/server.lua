local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Numpad = {}

if IS_CORE then
    function Numpad.Open(playerId, pin, showPin)
        if not playerId or playerId <= 0 then return end
        return MSK.Trigger('msk_core:numpad', playerId, pin, showPin)
    end
    exports('Numpad', Numpad.Open)

    function Numpad.Close(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:closeNumpad', playerId)
    end
    exports('CloseNumpad', Numpad.Close)

    MSK.Numpad = setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
    return MSK.Numpad
else
    function Numpad.Open(...) return exports.msk_core:Numpad(...) end
    function Numpad.Close(...) return exports.msk_core:CloseNumpad(...) end

    return setmetatable(Numpad, {
        __call = function(self, ...) return self.Open(...) end
    })
end
