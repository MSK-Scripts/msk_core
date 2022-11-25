MSK = {}
MSK.Timeouts = {}

local waitingRequest = {}
local Charset = {}
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

MSK.GetRandomLetter = function(length)
    Wait(0)
    if length > 0 then
        return MSK.GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
    else
        return ''
    end
end

MSK.TriggerCallback = function(name, ...)
    local requestId = GenerateRequestKey(waitingRequest)
    local response

    waitingRequest[requestId] = function(...)
        response = {...}
    end

    TriggerServerEvent('msk_core:triggerCallback', name, requestId, ...)

    while not response do
        Wait(0)
    end

    return table.unpack(response)
end

MSK.AddTimeout = function(ms, cb)
    table.insert(MSK.Timeouts, {time = GetGameTimer() + ms, cb = cb})
    return #MSK.Timeouts
end

MSK.DelTimeout = function(i)
    MSK.Timeouts[i] = nil
end

MSK.logging = function(code, msg, msg2, msg3)
    if code == 'error' then
        if msg3 then
			print('[^1ERROR^0]', msg, msg2, msg3)
        elseif msg2 and not msg3 then
            print('[^1ERROR^0]', msg, msg2)
        else
		    print('[^1ERROR^0]', msg)
        end
    elseif code == 'debug' then
		if msg3 then
			print('[^3DEBUG^0]', msg, msg2, msg3)
        elseif msg2 and not msg3 then
            print('[^3DEBUG^0]', msg, msg2)
        else
		    print('[^3DEBUG^0]', msg)
        end
	end
end

GenerateRequestKey = function(tbl)
    local id = string.upper(MSK.GetRandomLetter(3)) .. math.random(000, 999) .. string.upper(MSK.GetRandomLetter(2)) .. math.random(00, 99)

    if not tbl[id] then 
        return tostring(id)
    else
        GenerateRequestKey(tbl)
    end
end

RegisterNetEvent("msk_core:responseCallback")
AddEventHandler("msk_core:responseCallback", function(requestId, ...)
    if waitingRequest[requestId] then 
        waitingRequest[requestId](...)
        waitingRequest[requestId] = nil
    end
end)

CreateThread(function()
    while true do
        local sleep = 100

        if #MSK.Timeouts > 0 then
            local currTime = GetGameTimer()
            sleep = 0

            for i = 1, #MSK.Timeouts, 1 do
                if currTime >= MSK.Timeouts[i].time then
                    MSK.Timeouts[i].cb()
                    MSK.Timeouts[i] = nil
                end
            end
        end

        Wait(sleep)
    end
end)

exports('getCoreObject', function()
    return MSK
end)