--------------------------------------------------------------------------------
-- MSK.HasItem (server)
--
-- Goes straight to the inventory adapter. It used to build a whole player
-- object first and call a function that had been glued onto it, which meant a
-- framework lookup for every item check.
--
--   MSK.HasItem(playerId, 'bread')                  -> item or false
--   MSK.HasItem(playerId, 'bread', 5)               -> item only with 5 or more
--   MSK.HasItem(playerId, 'bread', { quality = 1 }) -> metadata match
--   MSK.HasItem(playerId, { 'bread', 'water' })     -> first item found, or false
--------------------------------------------------------------------------------
MSK.HasItem = function(playerId, itemName, count, metadata)
    if not playerId then
        MSK.Logging('error', 'Player on function MSK.HasItem does not exist!')
        return false
    end

    if MSK.Bridge.Framework.Type == 'STANDALONE' then
        MSK.Logging('error', 'Function "MSK.HasItem" cannot be used without a framework!')
        return false
    end

    -- Third argument may be the metadata table (short form without a count).
    if type(count) == 'table' then
        metadata, count = count, nil
    end

    count = tonumber(count) or 1

    local getItem = MSK.Bridge.InventoryAdapter.getItem
    if not getItem then
        MSK.Logging('error', ('Inventory "%s" does not support item lookups.'):format(MSK.Bridge.Inventory))
        return false
    end

    local names = type(itemName) == 'table' and itemName or { itemName }

    for i = 1, #names do
        local item = getItem(playerId, names[i], metadata)

        if item and (item.count or item.amount or 0) >= count then
            item.count = item.count or item.amount
            return item
        end
    end

    return false
end
exports('HasItem', MSK.HasItem)
MSK.Register('msk_core:hasItem', MSK.HasItem)
