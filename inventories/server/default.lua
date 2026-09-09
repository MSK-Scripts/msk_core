if MSK.Bridge.Inventory ~= 'default' then return end

--------------------------------------------------------------------------------
-- Built-in inventory of the running framework
--
-- 'default' means: no separate inventory resource was found, so items are
-- handled by the framework itself (ESX default / Chezza inventory, or the item
-- functions qb-core and Qbox carry on Player.Functions).
--
-- This adapter exists so that the framework bridges hold no item code at all.
-- Framework and inventory are two independent axes, and mixing them is what
-- made the old FunctionOverride path overwrite framework functions after the
-- fact.
--------------------------------------------------------------------------------
local Inventory = MSK.Bridge.InventoryAdapter
local framework = MSK.Bridge.Framework.Type

local function raw(playerId)
    return MSK.Bridge.Adapter.getBySource(playerId)
end

--------------------------------------------------------------------------------
-- ESX default inventory
--------------------------------------------------------------------------------
if framework == 'ESX' then
    function Inventory.getInventory(playerId)
        local xPlayer = raw(playerId)
        return xPlayer and xPlayer.getInventory() or {}
    end

    function Inventory.getItem(playerId, name)
        local xPlayer = raw(playerId)
        return xPlayer and xPlayer.getInventoryItem(name) or nil
    end

    function Inventory.addItem(playerId, name, count)
        local xPlayer = raw(playerId)
        if not xPlayer then return false end

        xPlayer.addInventoryItem(name, count or 1)
        return true
    end

    function Inventory.removeItem(playerId, name, count)
        local xPlayer = raw(playerId)
        if not xPlayer then return false end

        xPlayer.removeInventoryItem(name, count or 1)
        return true
    end

    function Inventory.addWeapon(playerId, name, count)
        local xPlayer = raw(playerId)
        if not xPlayer then return false end

        xPlayer.addWeapon(name, count or 0)
        return true
    end

    function Inventory.removeWeapon(playerId, name)
        local xPlayer = raw(playerId)
        if not xPlayer then return false end

        xPlayer.removeWeapon(name)
        return true
    end

    function Inventory.getWeapon(playerId, name)
        local xPlayer = raw(playerId)
        if not xPlayer then return nil end

        local hasWeapon, weapon = xPlayer.hasWeapon(name)
        return hasWeapon and (weapon or { name = name, count = 1 }) or nil
    end

    function Inventory.canCarryItem(playerId, name, count)
        local xPlayer = raw(playerId)
        if not xPlayer then return nil end

        return xPlayer.canCarryItem(name, count or 1)
    end

    function Inventory.canSwapItem(playerId, firstItem, firstCount, secondItem, secondCount)
        local xPlayer = raw(playerId)
        if not xPlayer then return nil end

        return xPlayer.canSwapItem(firstItem, firstCount, secondItem, secondCount)
    end

    function Inventory.setMaxWeight(playerId, maxWeight)
        local xPlayer = raw(playerId)
        if not xPlayer or not xPlayer.setMaxWeight then return nil end

        xPlayer.setMaxWeight(maxWeight)
        return true
    end

    function Inventory.clear(playerId)
        local xPlayer = raw(playerId)
        if not xPlayer then return false end

        -- ESX has no clear, so every item is set to zero one by one.
        for _, item in pairs(xPlayer.getInventory() or {}) do
            if (item.count or 0) > 0 then
                xPlayer.setInventoryItem(item.name, 0)
            end
        end

        -- Weapons live in a separate loadout here. On ox_inventory they are
        -- items and the loop above already caught them, which is why this only
        -- exists in the ESX branch.
        for _, weapon in pairs(xPlayer.loadout or {}) do
            xPlayer.removeWeapon(weapon.name)
        end

        return true
    end

--------------------------------------------------------------------------------
-- QBCore and Qbox item functions on Player.Functions
--
-- Argument order differs from the unified signature: both frameworks take
-- AddItem(item, amount, slot, metadata).
--------------------------------------------------------------------------------
elseif framework == 'QBCore' or framework == 'Qbox' then
    function Inventory.getInventory(playerId)
        local player = raw(playerId)
        return player and player.PlayerData.items or {}
    end

    function Inventory.getItem(playerId, name)
        local player = raw(playerId)
        if not player or not player.Functions.GetItemByName then return nil end

        return player.Functions.GetItemByName(name)
    end

    function Inventory.addItem(playerId, name, count, metadata, slot)
        local player = raw(playerId)
        if not player or not player.Functions.AddItem then return false end

        return player.Functions.AddItem(name, count or 1, slot, metadata) and true or false
    end

    function Inventory.removeItem(playerId, name, count, metadata, slot)
        local player = raw(playerId)
        if not player or not player.Functions.RemoveItem then return false end

        return player.Functions.RemoveItem(name, count or 1, slot) and true or false
    end

    Inventory.addWeapon = function(...) return Inventory.addItem(...) end
    Inventory.removeWeapon = function(...) return Inventory.removeItem(...) end
    Inventory.getWeapon = function(...) return Inventory.getItem(...) end

    -- Neither framework exposes a carry check of its own, the inventory
    -- resource owns that. nil says "cannot be checked" instead of promising
    -- space that may not exist.
    function Inventory.canCarryItem()
        return nil
    end

    function Inventory.canSwapItem()
        return nil
    end

    function Inventory.setMaxWeight()
        return nil
    end

    function Inventory.clear(playerId)
        local player = raw(playerId)
        if not player or not player.Functions.ClearInventory then return false end

        player.Functions.ClearInventory()
        return true
    end
end
