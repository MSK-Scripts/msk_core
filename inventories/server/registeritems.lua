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

    local framework = MSK.Bridge.Framework.Type

    if framework == 'ESX' then
        ESX.RegisterUsableItem(itemName, callback)
    elseif framework == 'QBCore' then
        QBCore.Functions.CreateUseableItem(itemName, callback)
    elseif framework == 'Qbox' then
        QBX:CreateUseableItem(itemName, callback)
    elseif framework == 'STANDALONE' then
        -- Register the item here
    end
end
exports('RegisterItem', MSK.RegisterItem)
