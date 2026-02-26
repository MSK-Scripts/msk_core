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
        return exports['jaksam_inventory']:hasItem(playerId, item, quantity)
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        exports['jaksam_inventory']:addItem(playerId, item, count, metadata, slot)
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        exports['jaksam_inventory']:removeItem(playerId, item, count, metadata, slot)
    end

    Player.HasWeapon = function(weapon, metadata)
        return exports['jaksam_inventory']:hasItem(playerId, item, quantity)
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
