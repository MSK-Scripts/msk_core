if MSK.Bridge.Inventory ~= 'ox_inventory' then return end

FunctionOverride = function(Player)
    if GetResourceState('ox_inventory') ~= 'started' then return Player end
    local playerId = MSK.GetServerId(Player)
    Player.inventory = exports.ox_inventory:GetInventoryItems(playerId)
    Player.loadout = Player.inventory

    Player.GetInventory = function()
        return Player.inventory
    end

    Player.AddItem = function(item, count, metadata, slot)
        exports.ox_inventory:AddItem(playerId, item, count or 1, metadata, slot)
    end

    Player.RemoveItem = function(item, count, metadata, slot)
        exports.ox_inventory:RemoveItem(playerId, item, count or 1, metadata, slot)
    end

    Player.HasItem = function(item, metadata)
        return exports.ox_inventory:GetItem(playerId, item, metadata)
    end

    Player.AddMoney = function(accountName, money)
        exports.ox_inventory:AddItem(playerId, accountName, money)
    end

    Player.RemoveMoney = function(accountName, money)
        exports.ox_inventory:RemoveItem(playerId, accountName, money)
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        exports.ox_inventory:AddItem(playerId, weapon, count or 1, metadata, slot)
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        exports.ox_inventory:RemoveItem(playerId, weapon, count or 1, metadata, slot)
    end

    Player.HasWeapon = function(weapon, metadata)
        return exports.ox_inventory:GetItem(playerId, weapon, metadata)
    end

    Player.CanSwapItem = function(firstItem, firstItemCount, secondItem, secondItemCount)
        return exports.ox_inventory:CanSwapItem(playerId, firstItem, firstItemCount, secondItem, secondItemCount)
    end

    Player.CanCarryItem = function(name, count, metadata)
        return exports.ox_inventory:CanCarryItem(playerId, name, count, metadata)
    end

    Player.SetMaxWeight = function(maxWeight)
        exports.ox_inventory:Set(playerId, 'maxWeight', maxWeight)
    end

    return Player
end