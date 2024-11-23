if MSK.Bridge.Inventory ~= 'core_inventory' then return end

local CoreInventoryData
AddEventHandler("core_inventory:server:inventoryStarted", function(data)       
    CoreInventoryData = data
end)

FunctionOverride = function(Player)
    if GetResourceState('core_inventory') ~= 'started' then return Player end
    local playerId = MSK.GetServerId(Player)
    local identifier = MSK.GetIdentifier(Player)
    local inv = ('content-%s'):format(identifier:gsub(":", ""))

    Player.inventory = exports.core_inventory:getInventory(inv)
    Player.loadout = Player.inventory

    Player.GetInventory = function()
        return Player.inventory
    end

    Player.AddItem = function(item, count, metadata, slot)
        local result = exports.core_inventory:addItem(inv, item, count or 1, metadata)

        if result then
            TriggerClientEvent('core_inventory:client:notification', playerId, item, 'add', tonumber(count))
        end

        return result
    end

    Player.RemoveItem = function(item, count, metadata, slot)
        local result = exports.core_inventory:removeItem(inv, item, count or 1)

        if result then
            TriggerClientEvent('core_inventory:client:notification', playerId, item, 'remove', tonumber(count))
        end
        
        return result
    end

    Player.HasItem = function(item, metadata)
        return exports.core_inventory:hasItem(inv, item) and {count = exports.core_inventory:getItemCount(inv, item)}
    end

    Player.AddWeapon = function(weapon, count, metadata, slot)
        local result = exports.core_inventory:addItem(inv, weapon, count or 1, metadata)

        if result then
            TriggerClientEvent('core_inventory:client:notification', playerId, weapon, 'add', tonumber(count))
        end

        return result
    end

    Player.RemoveWeapon = function(weapon, count, metadata, slot)
        local result = exports.core_inventory:removeItem(inv, weapon, count or 1)

        if result then
            TriggerClientEvent('core_inventory:client:notification', playerId, weapon, 'remove', tonumber(count))
        end
        
        return result
    end

    Player.HasWeapon = function(weapon, metadata)
        return exports.core_inventory:hasItem(inv, weapon, nil)
    end

    Player.CanSwapItem = function(firstItem, firstItemCount, secondItem, secondItemCount)
        return exports.core_inventory:canCarry(inv, secondItem, secondItemCount)
    end

    Player.CanCarryItem = function(name, count, metadata)
        return exports.core_inventory:canCarry(inv, name, count, metadata)
    end

    Player.SetMaxWeight = function(maxWeight)
        -- No export found for that

        if MSK.Bridge.Framework.Type == 'ESX' then
            Player.setMaxWeight(maxWeight)
        end
    end

    return Player
end