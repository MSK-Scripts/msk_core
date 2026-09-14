--------------------------------------------------------------------------------
-- MSK.Controls (client)
--
-- Disables game controls for as long as needed, without a Wait(0) loop in the
-- calling script.
--
--   MSK.Controls.Disable(24, 25, 140)   -- attack, aim, melee
--   ...
--   MSK.Controls.Enable(24, 25, 140)
--
-- Disabling is counted: two parts of a script that both disable control 24
-- keep it disabled until both enabled it again. Clear() drops the count at
-- once. One thread per resource runs while anything is disabled and stops by
-- itself when nothing is.
--
-- Control ids: https://docs.fivem.net/docs/game-references/controls/
--------------------------------------------------------------------------------
local Controls = {}

local counts = {}
local running = false

local function collect(...)
    local list = {}

    for i = 1, select('#', ...) do
        local value = select(i, ...)

        if type(value) == 'table' then
            for j = 1, #value do
                list[#list + 1] = value[j]
            end
        elseif type(value) == 'number' then
            list[#list + 1] = value
        end
    end

    return list
end

local function start()
    if running then return end
    running = true

    CreateThread(function()
        while next(counts) do
            for control in pairs(counts) do
                DisableControlAction(0, control, true)
            end
            Wait(0)
        end

        running = false
    end)
end

---Disables the given controls (numbers or lists of numbers).
---@param ... number|number[]
function Controls.Disable(...)
    local list = collect(...)

    for i = 1, #list do
        local control = list[i]
        counts[control] = (counts[control] or 0) + 1
    end

    if #list > 0 then start() end
end

---Undoes one Disable for each of the given controls.
---@param ... number|number[]
function Controls.Enable(...)
    local list = collect(...)

    for i = 1, #list do
        local control = list[i]
        local count = counts[control]

        if count then
            counts[control] = count > 1 and count - 1 or nil
        end
    end
end

---Enables the given controls regardless of how often they were disabled.
---Without arguments every control of this resource is enabled.
---@param ... number|number[]
function Controls.Clear(...)
    if select('#', ...) == 0 then
        counts = {}
        return
    end

    local list = collect(...)
    for i = 1, #list do
        counts[list[i]] = nil
    end
end

---@param control number
---@return boolean
function Controls.IsDisabled(control)
    return counts[control] ~= nil
end

---List of all controls this resource keeps disabled.
---@return number[]
function Controls.GetDisabled()
    local list = {}
    for control in pairs(counts) do
        list[#list + 1] = control
    end
    table.sort(list)
    return list
end

return Controls
