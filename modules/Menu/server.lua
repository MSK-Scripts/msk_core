local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Menu = {}

if IS_CORE then
    -- Opens a menu for a player: either one registered on the client, by id, or
    -- an inline menu (serialisable fields only, so event/serverEvent/args).
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
    Menu.Close = Menu.Hide -- Alias
    MSK.HideMenu = Menu.Hide
    exports('HideMenu', Menu.Hide)

    MSK.Menu = setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Menu
else
    function Menu.Show(...) return exports.msk_core:ShowMenu(...) end
    function Menu.Hide(...) return exports.msk_core:HideMenu(...) end
    Menu.Close = Menu.Hide -- Alias

    return setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
end
