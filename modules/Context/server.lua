local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Context = {}

if IS_CORE then
    -- Oeffnet bei einem Spieler ein (client-seitig registriertes) Context-Menue
    -- per id, oder ein inline-Menue (nur serialisierbare Felder: event/serverEvent/args).
    function Context.Show(playerId, idOrData)
        if not playerId or playerId <= 0 then return end
        return MSK.Trigger('msk_core:context', playerId, idOrData)
    end
    MSK.ShowContext = Context.Show
    exports('ShowContext', Context.Show)

    function Context.Hide(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:hideContext', playerId)
    end
    MSK.HideContext = Context.Hide
    exports('HideContext', Context.Hide)

    MSK.Context = setmetatable(Context, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Context
else
    function Context.Show(...) return exports.msk_core:ShowContext(...) end
    function Context.Hide(...) return exports.msk_core:HideContext(...) end

    return setmetatable(Context, {
        __call = function(self, ...) return self.Show(...) end
    })
end
