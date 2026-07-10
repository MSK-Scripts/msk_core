local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Menu = {}

if IS_CORE then
    -- Oeffnet bei einem Spieler ein (client-seitig registriertes) Menue per id,
    -- oder ein inline-Menue (nur serialisierbare Felder: event/serverEvent/args).
    function Menu.Show(playerId, idOrData)
        if not playerId or playerId <= 0 then return end
        return MSK.Trigger('msk_core:menu', playerId, idOrData)
    end
    MSK.ShowMenu = Menu.Show
    exports('ShowMenu', Menu.Show)

    function Menu.Hide(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:hideMenu', playerId)
    end
    MSK.HideMenu = Menu.Hide
    exports('HideMenu', Menu.Hide)

    MSK.Menu = setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Menu
else
    function Menu.Show(...) return exports.msk_core:ShowMenu(...) end
    function Menu.Hide(...) return exports.msk_core:HideMenu(...) end

    return setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
end
