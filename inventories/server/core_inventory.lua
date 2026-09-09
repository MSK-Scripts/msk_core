if MSK.Bridge.Inventory ~= 'core_inventory' then return end

--------------------------------------------------------------------------------
-- core_inventory adapter
--
-- Ported, not fully maintained. ox_inventory and jaksam_inventory are the two
-- inventories with guaranteed support.
--
-- core_inventory addresses an inventory by name, not by server id, and builds
-- that name from the player identifier.
--------------------------------------------------------------------------------
local Inventory = MSK.Bridge.InventoryAdapter
local core = exports.core_inventory

local function ready()
    return GetResourceState('core_inventory') == 'started'
end

local function inventoryName(playerId)
    local identifier = MSK.GetPlayerIdentifier(playerId)
    if not identifier then return nil end

    return ('content-%s'):format(identifier:gsub(':', ''))
end

function Inventory.getInventory(playerId)
    local inv = ready() and inventoryName(playerId)
    return inv and core:getInventory(inv) or {}
end

function Inventory.getItem(playerId, name)
    local inv = ready() and inventoryName(playerId)
    if not inv or not core:hasItem(inv, name) then return nil end

    return {
        name  = name,
        count = core:getItemCount(inv, name),
    }
end

function Inventory.addItem(playerId, name, count, metadata)
    local inv = ready() and inventoryName(playerId)
    if not inv then return false end

    local result = core:addItem(inv, name, count or 1, metadata)

    if result then
        TriggerClientEvent('core_inventory:client:notification', playerId, name, 'add', tonumber(count) or 1)
    end

    return result and true or false
end

function Inventory.removeItem(playerId, name, count)
    local inv = ready() and inventoryName(playerId)
    if not inv then return false end

    local result = core:removeItem(inv, name, count or 1)

    if result then
        TriggerClientEvent('core_inventory:client:notification', playerId, name, 'remove', tonumber(count) or 1)
    end

    return result and true or false
end

Inventory.addWeapon = function(...) return Inventory.addItem(...) end
Inventory.removeWeapon = function(...) return Inventory.removeItem(...) end
Inventory.getWeapon = function(...) return Inventory.getItem(...) end

function Inventory.canCarryItem(playerId, name, count, metadata)
    local inv = ready() and inventoryName(playerId)
    if not inv then return nil end

    return core:canCarry(inv, name, count or 1, metadata)
end

-- core_inventory has no swap check. The old adapter answered with a carry check
-- on the second item, which is a different question, so this now says
-- "cannot be checked" instead.
function Inventory.canSwapItem()
    return nil
end

function Inventory.setMaxWeight(playerId, maxWeight)
    if MSK.Bridge.Framework.Type ~= 'ESX' then return nil end

    local xPlayer = MSK.Bridge.Adapter.getBySource(playerId)
    if not xPlayer or not xPlayer.setMaxWeight then return nil end

    xPlayer.setMaxWeight(maxWeight)
    return true
end
