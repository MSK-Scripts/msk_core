--------------------------------------------------------------------------------
-- MSK.Clipboard (client)
--
-- Copies text to the player's clipboard.
--
--   MSK.Clipboard.Set(('vec3(%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z))
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Clipboard = {}

if IS_CORE then
    ---@param text string|number
    function Clipboard.Set(text)
        assert(text ~= nil, 'Parameter "text" is nil on function MSK.Clipboard.Set')

        SendNUIMessage({
            action = 'setClipboard',
            value = tostring(text),
        })
    end

    exports('SetClipboard', Clipboard.Set)
    RegisterNetEvent('msk_core:setClipboard', Clipboard.Set)

    MSK.Clipboard = Clipboard
else
    function Clipboard.Set(text) return exports.msk_core:SetClipboard(text) end
end

return Clipboard
