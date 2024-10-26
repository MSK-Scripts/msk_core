MSK.TextUI = {}

local isTextUIOpen = false
local thread = false

MSK.TextUI.Show = function(key, text, color)
    if isTextUIOpen then return end
    isTextUIOpen = true

    SendNUIMessage({
		action = 'textUI',
		show = true,
		key = key or 'E',
		text = text or '',
		color = color or Config.TextUIColor,
	})
end
exports('ShowTextUI', MSK.TextUI.Show)
RegisterNetEvent("msk_core:textUiShow", MSK.TextUI.Show)

setmetatable(MSK.TextUI, {
    __call = function(self, ...)
        self.Show(...)
    end
})

MSK.TextUI.ShowThread = function(key, text, color)
    MSK.TextUI.Show(key, text, color)
    
    if thread then return end
    thread = true

    local timer = GetGameTimer()    
    CreateThread(function()
        while timer + 100 >= GetGameTimer() do Wait(100) end
        thread = false
        Wait(0)

        if not thread then
            MSK.TextUI.Hide()
        end
    end)
end
exports('ShowTextUIThread', MSK.TextUI.ShowThread)
RegisterNetEvent("msk_core:textUiShowThread", MSK.TextUI.ShowThread)

MSK.TextUI.Hide = function()
    if not isTextUIOpen then return end
    isTextUIOpen = false
    thread = false

	SendNUIMessage({
        action = 'textUI', 
        show = false
    })
end
exports('HideTextUI', MSK.TextUI.Hide)
RegisterNetEvent("msk_core:textUiHide", MSK.TextUI.Hide)

MSK.TextUI.Active = function()
    return isTextUIOpen
end
exports('TextUIActive', MSK.TextUI.Active)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    MSK.TextUI.Hide()
end)