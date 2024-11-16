if MSK.Bridge.Inventory ~= 'custom' then return end

FunctionOverride = function(Player)
    local playerId = MSK.GetServerId(Player)
    Player.inventory = exports['INVENTORY_SCRIPTS']:GetInventoryItems(playerId)
    Player.loadout = Player.inventory

    Player.GetInventory = function()
        return Player.inventory
    end

    Player.AddItem = function(item, count, metadata, slot)
        -- Add your code here
    end

    Player.RemoveItem = function(item, count, metadata, slot)
        -- Add your code here
    end

    Player.HasItem = function(item, metadata)
        return -- Add your code here
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        -- Add your code here
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        -- Add your code here
    end

    Player.HasWeapon = function(weapon, metadata)
        return -- Add your code here
    end

    Player.CanSwapItem = function(firstItem, firstItemCount, secondItem, secondItemCount)
        return -- Add your code here
    end

    Player.CanCarryItem = function(name, count, metadata)
        return -- Add your code here
    end

    Player.SetMaxWeight = function(maxWeight)
        -- Add your code here
    end

    return Player
end