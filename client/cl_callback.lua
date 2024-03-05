local callbackRequest = {}
local CallbackHandler = {}

AddEventHandler('onResourceStop', function(resource)
	if CallbackHandler[resource] then
        for k, handler in pairs(CallbackHandler[resource]) do
            RemoveEventHandler(handler)
        end
    end
end)

-- NEW Method for Client Callbacks
MSK.RegisterClientCallback = function(eventName, cb)
    local handler = RegisterNetEvent(('events-request-%s'):format(eventName), function (ticket, ...)
        TriggerServerEvent(('events-resolve-%s-%s'):format(eventName, ticket), cb(...))
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
MSK.Register = MSK.RegisterClientCallback
exports('RegisterClientCallback', MSK.RegisterClientCallback)

-- NEW Method for Server Callbacks
MSK.Trigger = function(eventName, ...)
    local p = promise.new()
    local ticket = tostring(GetGameTimer() .. GetPlayerServerId(PlayerId()))

    SetTimeout(5000, function()
        p:reject("Request Timed Out (408)")
    end)

    local handler = RegisterNetEvent(('events-resolve-%s-%s'):format(eventName, ticket), function(...)
        p:resolve({...})
    end)

    TriggerServerEvent(('events-request-%s'):format(eventName), ticket, ...)

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return table.unpack(result)
end

-- OLD Method for Server Callbacks
MSK.TriggerServerCallback = function(name, ...)
    local requestId = GenerateRequestKey(callbackRequest)
    local response

    callbackRequest[requestId] = function(...)
        response = {...}
    end

    TriggerServerEvent('msk_core:triggerCallback', name, requestId, ...)

    while not response do Wait(0) end

    return table.unpack(response)
end
MSK.TriggerCallback = MSK.TriggerServerCallback
exports('TriggerServerCallback', MSK.TriggerServerCallback)

GenerateRequestKey = function(tbl)
    local id = string.upper(MSK.GetRandomString(3)) .. math.random(000, 999) .. string.upper(MSK.GetRandomString(2)) .. math.random(00, 99)

    if not tbl[id] then 
        return tostring(id)
    else
        GenerateRequestKey(tbl)
    end
end

RegisterNetEvent("msk_core:responseCallback")
AddEventHandler("msk_core:responseCallback", function(requestId, ...)
    if callbackRequest[requestId] then 
        callbackRequest[requestId](...)
        callbackRequest[requestId] = nil
    end
end)