local Callbacks = {}
local CallbackHandler = {}

----------------------------------------------------------------
-- Server Callbacks
----------------------------------------------------------------
MSK.Register = function(eventName, cb)
    Callbacks[eventName] = cb
end
MSK.RegisterCallback = MSK.Register -- Support for old Scripts
exports('Register', MSK.Register)
exports('RegisterCallback', MSK.Register) -- Support for old Scripts

RegisterNetEvent('msk_core:server:triggerCallback', function(eventName, requestId, cb, ...)
    local playerId = source

    if not Callbacks[eventName] then 
        TriggerClientEvent('msk_core:client:callbackNotFound', playerId, requestId)
        return
    end

    if not cb then
        -- Method [return]
        TriggerClientEvent("msk_core:client:callbackResponse", playerId, requestId, Callbacks[eventName](playerId, ...))
    else
        -- Method [cb]
        Callbacks[eventName](playerId, function(...)
            TriggerClientEvent("msk_core:client:callbackResponse", playerId, requestId, ...)
        end, ...)
    end
end)

----------------------------------------------------------------
-- Client Callbacks
----------------------------------------------------------------
local GenerateCallbackHandlerKey = function()
    local requestId = math.random(1, 999999999)

    if not CallbackHandler[requestId] then 
        return tostring(requestId)
    else
        GenerateCallbackHandlerKey()
    end
end

MSK.Trigger = function(eventName, playerId, ...)
    local requestId = GenerateCallbackHandlerKey()
    local p = promise.new()
    CallbackHandler[requestId] = 'request'

    SetTimeout(5000, function()
        CallbackHandler[requestId] = nil
        p:reject(('Request Timed Out: [%s] [%s]'):format(eventName, requestId))
    end)

    TriggerClientEvent('msk_core:client:triggerClientCallback', playerId, playerId, eventName, requestId, ...)

    while CallbackHandler[requestId] == 'request' do Wait(0) end
    if not CallbackHandler[requestId] then return end

    p:resolve(CallbackHandler[requestId])
    CallbackHandler[requestId] = nil

    local result = Citizen.Await(p)
    return table.unpack(result)
end
MSK.TriggerCallback = MSK.Trigger -- Support for old Scripts
exports('Trigger', MSK.Trigger)
exports('TriggerCallback', MSK.Trigger) -- Support for old Scripts

RegisterNetEvent("msk_core:server:callbackResponse", function(requestId, ...)
	if not CallbackHandler[requestId] then return end
	CallbackHandler[requestId] = {...}
end)

RegisterNetEvent("msk_core:server:callbackNotFound", function(requestId)
	if not CallbackHandler[requestId] then return end
	CallbackHandler[requestId] = nil
end)

----------------------------------------------------------------
-- Server Callbacks with Method [return]
----------------------------------------------------------------
MSK.Register('msk_core:hasItem', function(source, itemName, metadata)
    return MSK.HasItem(source, itemName, metadata)
end)

MSK.Register('msk_core:isAceAllowed', function(source, command)
    return MSK.IsAceAllowed(source, command)
end)

MSK.Register('msk_core:isPrincipalAceAllowed', function(source, principal, ace)
    return MSK.IsPrincipalAceAllowed(principal, ace)
end)

-- For clientside MSK.RegisterCommand
MSK.Register('msk_core:doesPlayerExist', function(source, targetId)
    return DoesPlayerExist(targetId)
end)

-- For clientside MSK.RegisterCommand
MSK.Register('msk_core:getPlayerData', function(source, targetId)
    return MSK.GetPlayer({source = targetId})
end)

----------------------------------------------------------------
-- Server Callbacks with Method [cb]
----------------------------------------------------------------
MSK.Register('msk_core:ThisIsATest', function(source, cb, params, ...)
    cb(params, ...)
    
    -- Do something here with params, ...
end)