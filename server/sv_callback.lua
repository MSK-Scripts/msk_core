local Callbacks = {}
local CallbackHandler = {}

AddEventHandler('onResourceStop', function(resource)
	if CallbackHandler[resource] then
        for k, handler in pairs(CallbackHandler[resource]) do
            RemoveEventHandler(handler)
        end
    end
end)

MSK.Register = function(eventName, cb)
    local handler = RegisterNetEvent(('events-request-%s'):format(eventName), function(ticket, ...)
        logging('debug', ('events-request-%s'):format(eventName), ticket, source, cb, ...)
        TriggerClientEvent(('events-resolve-%s-%s'):format(eventName, ticket), source, cb(source, ...))
    end)

    local script = GetInvokingResource()
    if script then 
        if CallbackHandler[script] then
            table.insert(CallbackHandler[script], handler)
        else
            CallbackHandler[script] = {}
            table.insert(CallbackHandler[script], handler)
        end
    end
end

-- NEW Method for Client Callbacks
MSK.TriggerClientCallback = function(eventName, playerId, ...)
    local p = promise.new()
    local ticket = GetGameTimer() .. playerId

    SetTimeout(5000, function()
        p:reject("Request Timed Out (408)")
    end)

    local handler = RegisterNetEvent(('events-resolve-%s-%s'):format(eventName, ticket), function(...)
        p:resolve({...})
    end)

    TriggerClientEvent(('events-request-%s'):format(eventName), playerId, ticket, ...)

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return table.unpack(result)
end
MSK.Trigger = MSK.TriggerClientCallback
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