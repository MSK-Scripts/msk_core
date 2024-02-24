local callbackRequest = {}

-- NEW Method for Client Callbacks
MSK.RegisterClientCallback = function(name, cb)
    RegisterNetEvent(('events-request-%s'):format(name), function (ticket, ...)
        TriggerServerEvent(('events-resolve-%s-%s'):format(name, ticket), cb(...))
    end)
end
exports('RegisterClientCallback', MSK.RegisterClientCallback)

-- NEW Method for Server Callbacks
MSK.Trigger = function(name, ...)
    local p = promise.new()
    local ticket = GetGameTimer() .. GetPlayerServerId(PlayerId())

    SetTimeout(5000, function()
        p:reject({err="Request Timed Out (408)"})
    end)

    local handler = RegisterNetEvent(('events-resolve-%s-%s'):format(name, ticket), function(data)
        p:resolve(data)
    end)

    TriggerServerEvent(('events-request-%s'):format(name), ticket, ...)

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return result
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