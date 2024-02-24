local Callbacks = {}

-- NEW Method for Server Callbacks
MSK.Register = function(name, cb)
    RegisterNetEvent(('events-request-%s'):format(name), function (ticket, ...)
        TriggerClientEvent(('events-resolve-%s-%s'):format(name, ticket), source, cb(source, ...))
    end) 
end

-- NEW Method for Client Callbacks
MSK.TriggerClientCallback = function(name, playerId, ...)
    local p = promise.new()
    local ticket = GetGameTimer() .. playerId

    SetTimeout(5000, function()
        p:reject({err="Request Timed Out (408)"})
    end)

    local handler = RegisterNetEvent(('events-resolve-%s-%s'):format(name, ticket), function(data)
        p:resolve(data)
    end)

    TriggerClientEvent(('events-request-%s'):format(name), playerId, ticket, ...)

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return result
end
exports('TriggerClientCallback', MSK.TriggerClientCallback)

-- OLD Method for Server Callbacks
MSK.RegisterServerCallback = function(name, cb)
    Callbacks[name] = cb
end
MSK.RegisterCallback = MSK.RegisterServerCallback
exports('RegisterServerCallback', MSK.RegisterServerCallback)

RegisterNetEvent('msk_core:triggerCallback')
AddEventHandler('msk_core:triggerCallback', function(name, requestId, ...)
    local src = source
    if Callbacks[name] then
        Callbacks[name](src, function(...)
            TriggerClientEvent("msk_core:responseCallback", src, requestId, ...)
        end, ...)
    end
end)

-- Server Callback with NEW Method
MSK.Register('msk_core:hasItem', function(source, item)
    local src = source
    local xPlayer

    if Config.Framework:match('esx') then
        xPlayer = ESX.GetPlayerFromId(src)
    elseif Config.Framework:match('qbcore') then
        xPlayer = QBCore.Functions.GetPlayer(src)
    end

    return MSK.HasItem(xPlayer, item)
end)