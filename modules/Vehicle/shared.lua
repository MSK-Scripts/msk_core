-- Shared part of the Vehicle module. Loaded in front of client.lua / server.lua
-- by the module loader, so the locals in here are in scope for both sides.

---Normalises a plate for comparison. BOTH sides of every plate comparison have
---to run through this, otherwise the two sides never match.
---
---GTA plates are 8 characters and the natives hand them back space padded
---("ABC123  "), while a plate coming from a database, a command or a config is
---usually stored trimmed and not necessarily upper case.
---
---Inner spaces are deliberately kept: "AB C123" and "ABC123" are two different
---plates and must not match each other.
---@param plate any anything stringable
---@return string|nil normalised plate, nil when empty or missing
local function normalizePlate(plate)
    if plate == nil then return nil end

    plate = MSK.String.Trim(tostring(plate)):upper()
    if plate == '' then return nil end

    return plate
end
