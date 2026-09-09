if MSK.Bridge.Inventory ~= 'custom' then return end

--------------------------------------------------------------------------------
-- Your own inventory
--
-- Set Config.Inventory = 'custom' and fill in the functions below. Everything
-- msk_core does with items goes through this table, so a filled-in function is
-- immediately used everywhere: MSK.HasItem, the player object, and every MSK
-- script running on this server.
--
-- Signatures are the same for every adapter:
--   playerId  server id, never the framework player object
--   count     defaults to 1 when nil
--   returns   true / false for actions, the item table or nil for lookups
--
-- Leave a function out and it stays nil, which msk_core reports as "this
-- inventory cannot do that" instead of guessing an answer. That matters most
-- for canCarryItem: returning true without checking makes items vanish.
--------------------------------------------------------------------------------
local Inventory = MSK.Bridge.InventoryAdapter

---@param playerId number
---@return table
function Inventory.getInventory(playerId)
    return {}
end

---@param playerId number
---@param name string
---@param metadata table?
---@return table? item with at least { name = string, count = number }
function Inventory.getItem(playerId, name, metadata)
    return nil
end

---@return boolean
function Inventory.addItem(playerId, name, count, metadata, slot)
    return false
end

---@return boolean
function Inventory.removeItem(playerId, name, count, metadata, slot)
    return false
end

---@return boolean
function Inventory.addWeapon(playerId, name, count, metadata, slot)
    return false
end

---@return boolean
function Inventory.removeWeapon(playerId, name, count, metadata, slot)
    return false
end

---@return table?
function Inventory.getWeapon(playerId, name, metadata)
    return nil
end

---@return boolean? nil means the inventory cannot answer this
function Inventory.canCarryItem(playerId, name, count, metadata)
    return nil
end

---@return boolean? nil means the inventory cannot answer this
function Inventory.canSwapItem(playerId, firstItem, firstCount, secondItem, secondCount)
    return nil
end

---@param maxWeight number in kilograms
---@return boolean?
function Inventory.setMaxWeight(playerId, maxWeight)
    return nil
end
