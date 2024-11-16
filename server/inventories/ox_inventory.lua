if MSK.Bridge.Inventory ~= 'ox_inventory' then return end

local Inventory
AddEventHandler("ox_inventory:loadInventory", function(module)
    Inventory = module
end)

FunctionOverride = function(Player)
    if GetResourceState('ox_inventory') ~= 'started' then return Player end
    local playerId = MSK.GetServerId(Player)

    Player.inventory = exports.ox_inventory:GetInventoryItems(playerId)
    Player.loadout = Player.inventory

    Player.GetInventory = function()
        return Player.inventory
    end

    Player.AddItem = function(item, count, metadata, slot)
        return Inventory.AddItem(playerId, item, count or 1, metadata, slot)
    end

    Player.RemoveItem = function(item, count, metadata, slot)
        return Inventory.RemoveItem(playerId, item, count or 1, metadata, slot)
    end

    Player.HasItem = function(item, metadata)
        return Inventory.GetItem(playerId, item, metadata)
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        return Inventory.AddItem(playerId, weapon, 1, metadata or {ammo = count}, slot)
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        return Inventory.RemoveItem(playerId, weapon, count or 1, metadata, slot)
    end

    Player.HasWeapon = function(weapon, metadata)
        return Inventory.GetItem(playerId, weapon, metadata)
    end

    Player.CanSwapItem = function(firstItem, firstItemCount, secondItem, secondItemCount)
        return Inventory.CanSwapItem(playerId, firstItem, firstItemCount, secondItem, secondItemCount)
    end

    Player.CanCarryItem = function(name, count, metadata)
        return Inventory.CanCarryItem(playerId, name, count, metadata)
    end

    Player.SetMaxWeight = function(maxWeight)
        return Inventory.SetMaxWeight(playerId, maxWeight * 1000)
    end

    if MSK.Bridge.Framework.Type == 'OXCore' then
        Player.AddMoney = function(accountName, money)
            if money < 1 then return end
            accountName = accountName:lower()

            if Inventory.accounts[accountName] then
                Inventory.AddItem(playerId, accountName, money)
            elseif accountName == 'bank' then
                local account = Player.getAccount()
                return account and account.addBalance({ money }) or false
            end
        end
    
        Player.RemoveMoney = function(accountName, money)
            if money < 1 then return end
            accountName = accountName:lower()

            if Inventory.accounts[accountName] then
                Inventory.RemoveItem(playerId, accountName, money)
            elseif accountName == 'bank' then
                local account = Player.getAccount()
                return account and account.removeBalance({ money }) or false
            end
        end
    end

    return Player
end