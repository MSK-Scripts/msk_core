if MSK.Bridge.Inventory ~= 'ox_inventory' then return end

--------------------------------------------------------------------------------
-- ox_inventory adapter
--
-- Goes through the documented exports rather than the internal module handed
-- out by the ox_inventory:loadInventory event. The event only arrives if
-- ox_inventory starts after this resource, and until then every call through
-- the module reference failed on a nil value.
--------------------------------------------------------------------------------
local Inventory = MSK.Bridge.InventoryAdapter
local ox = exports.ox_inventory

local function ready()
    return GetResourceState('ox_inventory') == 'started'
end

function Inventory.getInventory(playerId)
    if not ready() then return {} end
    return ox:GetInventoryItems(playerId) or {}
end

function Inventory.getItem(playerId, name, metadata)
    if not ready() then return nil end
    return ox:GetItem(playerId, name, metadata)
end

function Inventory.addItem(playerId, name, count, metadata, slot)
    if not ready() then return false end
    return ox:AddItem(playerId, name, count or 1, metadata, slot) and true or false
end

function Inventory.removeItem(playerId, name, count, metadata, slot)
    if not ready() then return false end
    return ox:RemoveItem(playerId, name, count or 1, metadata, slot) and true or false
end

-- In ox_inventory a weapon is an item, ammo lives in its metadata.
function Inventory.addWeapon(playerId, name, count, metadata, slot)
    if not ready() then return false end
    return ox:AddItem(playerId, name, 1, metadata or { ammo = count }, slot) and true or false
end

function Inventory.removeWeapon(playerId, name, count, metadata, slot)
    if not ready() then return false end
    return ox:RemoveItem(playerId, name, count or 1, metadata, slot) and true or false
end

function Inventory.getWeapon(playerId, name, metadata)
    if not ready() then return nil end
    return ox:GetItem(playerId, name, metadata)
end

function Inventory.canCarryItem(playerId, name, count, metadata)
    if not ready() then return nil end
    return ox:CanCarryItem(playerId, name, count or 1, metadata)
end

function Inventory.canSwapItem(playerId, firstItem, firstCount, secondItem, secondCount)
    if not ready() then return nil end
    return ox:CanSwapItem(playerId, firstItem, firstCount, secondItem, secondCount)
end

function Inventory.setMaxWeight(playerId, maxWeight)
    if not ready() then return nil end

    -- ox_inventory counts weight in grams, the unified signature takes
    -- kilograms like every other adapter here.
    ox:SetMaxWeight(playerId, maxWeight * 1000)
    return true
end

function Inventory.clear(playerId, keep)
    if not ready() then return false end

    ox:ClearInventory(playerId, keep)
    return true
end
