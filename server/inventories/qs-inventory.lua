if MSK.Bridge.Inventory ~= 'qs-inventory' then return end

FunctionOverride = function(Player)
    if GetResourceState('qs-inventory') ~= 'started' then return Player end
    local playerId = MSK.GetServerId(Player)
    Player.inventory = exports['qs-inventory']:GetInventory(playerId)
    Player.loadout = Player.inventory

    Player.GetInventory = function()
        return Player.inventory
    end

    Player.AddItem = function(item, count, metadata, slot)
        exports['qs-inventory']:AddItem(playerId, item, count or 1, slot, metadata)
    end

    Player.RemoveItem = function(item, count, metadata, slot)
        exports['qs-inventory']:RemoveItem(playerId, item, count or 1, slot, metadata)
    end

    Player.HasItem = function(itemName, metadata)
        local item = exports['qs-inventory']:GetItemByName(playerId, itemName)
        if not item then item = {amount = 0} end
        item.count = item.amount
        return item
    end

    Player.AddMoney = function(accountName, money)
        exports['qs-inventory']:AddItem(playerId, accountName, money)
    end

    Player.RemoveMoney = function(accountName, money)
        exports['qs-inventory']:RemoveItem(playerId, accountName, money)
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        exports['qs-inventory']:GiveWeaponToPlayer(playerId, weapon, count)
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        exports['qs-inventory']:RemoveItem(playerId, weapon, count or 1, slot, metadata)
    end

    Player.HasWeapon = function(weapon, metadata)
        return exports.ox_inventory:GetItem(playerId, weapon, metadata)
    end

    Player.CanSwapItem = function(firstItem, firstItemCount, secondItem, secondItemCount)
        return true
    end

    Player.CanCarryItem = function(name, count, metadata)
        return exports['qs-inventory']:CanCarryItem(playerId, name, count)
    end

    Player.SetMaxWeight = function(maxWeight)
        -- No export found for that
    end

    return Player
end