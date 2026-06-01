MSK.HasItem = function(itemName, metadata)
    if MSK.Bridge.Framework.Type == 'STANDALONE' then
        MSK.Logging('error', 'Function "MSK.HasItem" cannot be used without Framework!')
        return
    end

    return MSK.Trigger('msk_core:hasItem', itemName, metadata)
end
exports('HasItem', MSK.HasItem)
