--------------------------------------------------------------------------------
-- MSK.HasItem (client)
--
-- Asks the server, because the client must never be the authority on what a
-- player carries. Same argument shape as the server version:
--
--   MSK.HasItem('bread')                  -> item or false
--   MSK.HasItem('bread', 5)               -> item only with 5 or more
--   MSK.HasItem('bread', { quality = 1 }) -> metadata match
--   MSK.HasItem({ 'bread', 'water' })     -> first item found, or false
--------------------------------------------------------------------------------
MSK.HasItem = function(itemName, count, metadata)
    if MSK.Bridge.Framework.Type == 'STANDALONE' then
        MSK.Logging('error', 'Function "MSK.HasItem" cannot be used without a framework!')
        return false
    end

    return MSK.Trigger('msk_core:hasItem', itemName, count, metadata)
end
exports('HasItem', MSK.HasItem)
