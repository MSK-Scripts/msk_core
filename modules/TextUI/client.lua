local IS_CORE = GetCurrentResourceName() == 'msk_core'
local TextUI = {}

if IS_CORE then
    local isTextUIOpen = false
    local thread = false
    local timer = 0

    function TextUI.Show(key, text, color)
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

    function TextUI.ShowThread(key, text, color)
        TextUI.Show(key, text, color)

        timer = GetGameTimer()

        if thread then return end
        thread = true

        CreateThread(function()
            while timer + 100 >= GetGameTimer() do Wait(100) end
            thread = false
            Wait(0)

            if not thread then
                TextUI.Hide()
            end
        end)
    end

    function TextUI.Hide()
        if not isTextUIOpen then return end
        isTextUIOpen = false
        thread = false

        SendNUIMessage({ action = 'textUI', show = false })
    end

    function TextUI.Active()
        return isTextUIOpen
    end

    exports('ShowTextUI', TextUI.Show)
    exports('ShowTextUIThread', TextUI.ShowThread)
    exports('HideTextUI', TextUI.Hide)
    exports('TextUIActive', TextUI.Active)

    RegisterNetEvent("msk_core:textUiShow", TextUI.Show)
    RegisterNetEvent("msk_core:textUiShowThread", TextUI.ShowThread)
    RegisterNetEvent("msk_core:textUiHide", TextUI.Hide)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        TextUI.Hide()
    end)

    MSK.TextUI = setmetatable(TextUI, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.TextUI
else
    function TextUI.Show(...) return exports.msk_core:ShowTextUI(...) end
    function TextUI.ShowThread(...) return exports.msk_core:ShowTextUIThread(...) end
    function TextUI.Hide() return exports.msk_core:HideTextUI() end
    function TextUI.Active() return exports.msk_core:TextUIActive() end

    return setmetatable(TextUI, {
        __call = function(self, ...) return self.Show(...) end
    })
end
