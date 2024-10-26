MSK.Input = {}
MSK.Numpad = {}
MSK.Progress = {}
MSK.TextUI = {}

----------------------------------------------------------------
-- MSK.Input
----------------------------------------------------------------
MSK.Input.Open = function(playerId, header, placeholder, field)
    if not playerId or playerId <= 0 then return end
    return MSK.Trigger('msk_core:input', playerId, header, placeholder, field)
end
exports('Input', MSK.Input.Open)
exports('OpenInput', MSK.Input.Open)

setmetatable(MSK.Input, {
    __call = function(self, ...)
        self.Open(...)
    end
})

MSK.Input.Close = function(playerId)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:closeInput', playerId)
end
MSK.CloseInput = MSK.Input.Close
exports('CloseInput', MSK.Input.Close)

----------------------------------------------------------------
-- MSK.Numpad
----------------------------------------------------------------
MSK.Numpad.Open = function(playerId, pin, showPin)
    if not playerId or playerId <= 0 then return end
    return MSK.Trigger('msk_core:numpad', playerId, pin, showPin)
end
exports('Numpad', MSK.Numpad.Open)

setmetatable(MSK.Numpad, {
    __call = function(self, ...)
        self.Open(...)
    end
})

MSK.Numpad.Close = function(playerId)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:closeNumpad', playerId)
end
exports('CloseNumpad', MSK.Numpad.Close)

----------------------------------------------------------------
-- MSK.Progress
----------------------------------------------------------------
MSK.Progress.Start = function(playerId, data, text, color)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:progressbar', playerId, data, text, color)
end
MSK.Progressbar = MSK.Progress.Start
exports('Progressbar', MSK.Progress.Start)

setmetatable(MSK.Progress, {
    __call = function(self, ...)
        self.Start(...)
    end
})

MSK.Progress.Stop = function(playerId)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:progressbarStop', playerId)
end
exports('ProgressStop', MSK.Progress.Stop)

----------------------------------------------------------------
-- MSK.TextUI
----------------------------------------------------------------
MSK.TextUI.Show = function(playerId, key, text, color)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:textUiShow', playerId, key, text, color)
end
exports('ShowTextUI', MSK.TextUI.Show)

setmetatable(MSK.TextUI, {
    __call = function(self, ...)
        self.Show(...)
    end
})

MSK.TextUI.ShowThread = function(playerId, key, text, color)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:textUiShowThread', playerId, key, text, color)
end
exports('ShowTextUIThread', MSK.TextUI.ShowThread)

MSK.TextUI.Hide = function(playerId)
    if not playerId or playerId <= 0 then return end
    TriggerClientEvent('msk_core:textUiHide', playerId)
end
exports('HideTextUI', MSK.TextUI.Hide)