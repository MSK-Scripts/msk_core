local RegisteredItems = {}

MSK.GetRegisteredItems = function()
    return RegisteredItems
end
exports('GetRegisteredItems', MSK.GetRegisteredItems)

MSK.GetRegisteredItem = function(itemName)
    return RegisteredItems[itemName] or false
end
exports('GetRegisteredItem', MSK.GetRegisteredItem)

MSK.RegisterItem = function(itemName, callback)
    if RegisteredItems[itemName] then
        MSK.Logging('info', ('Item ^3%s^0 is already registerd. Overriding Item...'):format(itemName))
    end

    RegisteredItems[itemName] = callback

    if MSK.Bridge.Framework.Type == 'ESX' then
        ESX.RegisterUsableItem(itemName, callback)
    elseif MSK.Bridge.Framework.Type == 'QBCore' then
        QBCore.Functions.CreateUseableItem(itemName, callback)
    elseif MSK.Bridge.Framework.Type == 'STANDALONE' then
        -- Register the item here
    end
end
exports('RegisterItem', MSK.RegisterItem)
