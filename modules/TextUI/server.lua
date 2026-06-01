local IS_CORE = GetCurrentResourceName() == 'msk_core'
local TextUI = {}

if IS_CORE then
    function TextUI.Show(playerId, key, text, color)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:textUiShow', playerId, key, text, color)
    end

    function TextUI.ShowThread(playerId, key, text, color)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:textUiShowThread', playerId, key, text, color)
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
