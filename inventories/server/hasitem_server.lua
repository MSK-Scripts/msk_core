MSK.HasItem = function(playerId, itemName, metadata)
    if not playerId then
        MSK.Logging('error', 'Player on Function MSK.HasItem does not exist!')
        return false
    end

    if MSK.Bridge.Framework.Type == 'STANDALONE' then
        MSK.Logging('error', 'Function "MSK.HasItem" cannot be used without Framework!')
        return false
    end

    local Player = MSK.GetPlayer({source = playerId})

    if type(itemName) ~= 'table' then
        return Player.HasItem(itemName, metadata)
    end

    for i = 1, #itemName do
        local item = itemName[i]
        local hasItem = Player.HasItem(item, metadata)

        if hasItem then
            return hasItem
        end
    end

    return false
end
exports('HasItem', MSK.HasItem)
MSK.Register('msk_core:hasItem', MSK.HasItem)
