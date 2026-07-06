if MSK.Bridge.Inventory ~= 'jaksam_inventory' then return end

FunctionOverride = function(Player)
    if GetResourceState('jaksam_inventory') ~= 'started' then return Player end
    local playerId = MSK.GetServerId(Player)

    Player.inventory = exports['jaksam_inventory']:getInventory(playerId)
    Player.loadout = Player.inventory

    Player.GetInventory = function()
        return Player.inventory
    end

    Player.AddItem = function(item, count, metadata, slot)
        exports['jaksam_inventory']:addItem(playerId, item, count, metadata, slot)
    end

    Player.RemoveItem = function(item, count, metadata, slot)
        exports['jaksam_inventory']:removeItem(playerId, item, count, metadata, slot)
    end

    Player.HasItem = function(item, metadata)
        local itemData = exports['jaksam_inventory']:getItemByName(playerId, item, metadata)
        if itemData and (itemData.amount or 0) > 0 then
            itemData.count = itemData.amount
            return itemData
        end
        return false
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        exports['jaksam_inventory']:addItem(playerId, weapon, count, metadata, slot)
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        exports['jaksam_inventory']:removeItem(playerId, weapon, count, metadata, slot)
    end

    Player.HasWeapon = function(weapon, metadata)
        local itemData = exports['jaksam_inventory']:getItemByName(playerId, weapon, metadata)
        if itemData and (itemData.amount or 0) > 0 then
            itemData.count = itemData.amount
            return itemData
        end
        return false
    end

    Player.CanSwapItem = function(firstItem, firstItemCount, secondItem, secondItemCount)
        return exports['jaksam_inventory']:canSwapItem(playerId, firstItem, firstItemCount, secondItem, secondItemCount)
    end

    Player.CanCarryItem = function(name, count, metadata)
        return exports['jaksam_inventory']:canCarryItem(playerId, name, count)
    end

    Player.SetMaxWeight = function(maxWeight)
        exports['jaksam_inventory']:setInventoryMaxWeight(playerId, maxWeight)
    end

    return Player
end
