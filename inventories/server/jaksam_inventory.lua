if MSK.Bridge.Inventory ~= 'jaksam_inventory' then return end

--------------------------------------------------------------------------------
-- jaksam_inventory adapter
--------------------------------------------------------------------------------
local Inventory = MSK.Bridge.InventoryAdapter
local jaksam = exports['jaksam_inventory']

local function ready()
    return GetResourceState('jaksam_inventory') == 'started'
end

-- jaksam returns `amount`, every other adapter here returns `count`. Normalise
-- it so consumer code never has to ask which inventory is running.
local function normalise(item)
    if not item then return nil end

    item.count = item.count or item.amount
    return item
end

function Inventory.getInventory(playerId)
    if not ready() then return {} end
    return jaksam:getInventory(playerId) or {}
end

function Inventory.getItem(playerId, name, metadata)
    if not ready() then return nil end
    return normalise(jaksam:getItemByName(playerId, name, metadata))
end

function Inventory.addItem(playerId, name, count, metadata, slot)
    if not ready() then return false end

    jaksam:addItem(playerId, name, count or 1, metadata, slot)
    return true
end

function Inventory.removeItem(playerId, name, count, metadata, slot)
    if not ready() then return false end

    jaksam:removeItem(playerId, name, count or 1, metadata, slot)
    return true
end

Inventory.addWeapon = function(...) return Inventory.addItem(...) end
Inventory.removeWeapon = function(...) return Inventory.removeItem(...) end
Inventory.getWeapon = function(...) return Inventory.getItem(...) end

function Inventory.canCarryItem(playerId, name, count)
    if not ready() then return nil end
    return jaksam:canCarryItem(playerId, name, count or 1)
end

function Inventory.canSwapItem(playerId, firstItem, firstCount, secondItem, secondCount)
    if not ready() then return nil end
    return jaksam:canSwapItem(playerId, firstItem, firstCount, secondItem, secondCount)
end

function Inventory.setMaxWeight(playerId, maxWeight)
    if not ready() then return nil end

    jaksam:setInventoryMaxWeight(playerId, maxWeight)
    return true
end
