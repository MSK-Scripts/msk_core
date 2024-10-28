local RegisteredItems = {}

MSK.GetRegisteredItems = function()
    return RegisteredItems
end
exports('GetRegisteredItems', MSK.GetRegisteredItems)

MSK.GetRegisteredItem = function(itemName)
    return RegisteredItems[itemName] or false
end
exports('GetRegisteredItem', MSK.GetRegisteredItem)

MSK.RegisterItem = function(itemName, cb)
    RegisteredItems[itemName] = cb

    if RegisteredItems[itemName] then
        MSK.Logging('info', ('Item ^3%s^0 is already registerd. Overriding Item...'):format(itemName))
    end

    if MSK.Bridge.Inventory == 'qs-inventory' then
        exports['qs-inventory']:CreateUsableItem(itemName, cb)
    elseif MSK.Bridge.Inventory ~= 'ox_inventory' then
        if MSK.Bridge.Framework.Type == 'ESX' then
            ESX.RegisterUsableItem(itemName, cb)
        elseif MSK.Bridge.Framework.Type == 'QBCore' then
            QBCore.Functions.CreateUseableItem(itemName, cb)
        end
    end

    if MSK.Bridge.Framework.Type == 'STANDALONE' then
        -- Register the item here
    end
end
exports('RegisterItem', MSK.RegisterItem)