--------------------------------------------------------------------------------
-- MSK.Keybind (client)
--
-- Key bindings the player can change in the GTA settings (Key Bindings ->
-- FiveM), with press and release handlers.
--
--   local bind = MSK.Keybind.Add({
--       name = 'my_script_menu',
--       description = 'Open the menu',
--       defaultKey = 'F5',
--       onPressed = function(self) OpenMenu() end,
--       onReleased = function(self) end,
--   })
--
--   bind:Disable(true)
--   bind:GetCurrentKey()   -- 'F5', or whatever the player changed it to
--
-- The name ends up as a command (+name / -name), so it has to be unique across
-- all resources. FiveM remembers the player's key per name: renaming a bind
-- throws the player's own choice away.
--------------------------------------------------------------------------------
local Keybind = {}

local binds = {}

local Bind = {}
Bind.__index = Bind

local function signedHash(value)
    value = value & 0xFFFFFFFF
    if value >= 0x80000000 then
        value = value - 0x100000000
    end
    return value
end

---Creates a key binding.
---`allowInPauseMenu` lets the binding fire while the pause menu is open, by
---default presses there are ignored.
---@param data { name: string, description: string, defaultKey?: string, defaultMapper?: string, secondaryKey?: string, secondaryMapper?: string, disabled?: boolean, allowInPauseMenu?: boolean, onPressed?: fun(self: table), onReleased?: fun(self: table) }
function Keybind.Add(data)
    assert(type(data) == 'table', 'Parameter "data" has to be a table on function MSK.Keybind.Add')
    assert(type(data.name) == 'string' and not data.name:find('%s'), 'Field "name" has to be a string without spaces on function MSK.Keybind.Add')
    assert(type(data.description) == 'string', 'Field "description" has to be a string on function MSK.Keybind.Add')

    if binds[data.name] then
        error(('Keybind "%s" already exists'):format(data.name), 2)
    end

    local self = setmetatable(data, Bind)
    self.defaultMapper = self.defaultMapper or 'keyboard'
    self.defaultKey = self.defaultKey or ''
    self.disabled = self.disabled == true
    self.pressed = false

    RegisterCommand('+' .. self.name, function()
        if self.disabled or (IsPauseMenuActive() and not self.allowInPauseMenu) then return end

        self.pressed = true

        if self.onPressed then
            local ok, err = pcall(self.onPressed, self)
            if not ok then print(('[^1ERROR^0] MSK.Keybind: onPressed of "%s" failed: %s'):format(self.name, err)) end
        end
    end, false)

    RegisterCommand('-' .. self.name, function()
        -- A release without a press happens when the key went down while the
        -- bind was disabled or the pause menu was open. Nothing to release.
        if not self.pressed then return end

        self.pressed = false

        if self.onReleased then
            local ok, err = pcall(self.onReleased, self)
            if not ok then print(('[^1ERROR^0] MSK.Keybind: onReleased of "%s" failed: %s'):format(self.name, err)) end
        end
    end, false)

    RegisterKeyMapping('+' .. self.name, self.description, self.defaultMapper, self.defaultKey)

    if self.secondaryKey then
        RegisterKeyMapping('~!+' .. self.name, self.description, self.secondaryMapper or self.defaultMapper, self.secondaryKey)
    end

    CreateThread(function()
        Wait(500)
        TriggerEvent('chat:removeSuggestion', '/+' .. self.name)
        TriggerEvent('chat:removeSuggestion', '/-' .. self.name)
    end)

    binds[self.name] = self
    return self
end

---Disables (true, default) or enables (false) the binding.
---@param state? boolean
function Bind:Disable(state)
    self.disabled = state ~= false

    if self.disabled and self.pressed then
        self.pressed = false

        if self.onReleased then
            pcall(self.onReleased, self)
        end
    end
end

---@return boolean
function Bind:IsDisabled()
    return self.disabled
end

---True while the key is held down.
---@return boolean
function Bind:IsPressed()
    return self.pressed
end

---The key currently bound, as shown in the settings, e.g. 'E' or 'F5'.
---@return string
function Bind:GetCurrentKey()
    local hash = signedHash(joaat('+' .. self.name) | 0x80000000)
    local key = GetControlInstructionalButton(0, hash, true) or ''

    return (key:gsub('^t_', ''))
end

---@param name string
---@return table?
function Keybind.Get(name)
    return binds[name]
end

---All bindings of this resource, keyed by name.
---@return table<string, table>
function Keybind.GetAll()
    return binds
end

return Keybind
