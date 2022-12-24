MSK = {}
MSK.Timeouts = {}

if Config.Framework:match('esx') then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework:match('qbcore') then
    QBCore = exports['qb-core']:GetCoreObject()
end

local callbackRequest = {}
local Letters = {}
for i = 48,  57 do table.insert(Letters, string.char(i)) end
for i = 65,  90 do table.insert(Letters, string.char(i)) end
for i = 97, 122 do table.insert(Letters, string.char(i)) end

MSK.GetRandomLetter = function(length)
    Wait(0)
    if length > 0 then
        return MSK.GetRandomLetter(length - 1) .. Letters[math.random(1, #Letters)]
    else
        return ''
    end
end

MSK.HasItem = function(item)
    if not Config.Framework:match('esx') or Config.Framework:match('qbcore') then 
        logging('error', ('Function %s can not used without Framework!'):format('MSK.HasItem'))
        return 
    end

    local hasItem = MSK.TriggerCallback('msk_core:hasItem', item)
    return hasItem
end

MSK.Notification = function(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
	DrawNotification(false, true)
end

MSK.HelpNotification = function(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

MSK.Draw3DText = function(coords, text, size, font)
    local coords = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)

    if not size then size = 1 end
    if not font then font = 0 end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, scale * 0.5)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

MSK.Table_Contains = function(table, value)
    if type(value) == 'table' then
        for k, v in pairs(table) do
            for k2, v2 in pairs(value) do
                if v == v2 then
                    return true
                end
            end
        end
    else
        for k, v in pairs(table) do
            if v == value then
                return true
            end
        end
    end
    return false
end

MSK.TriggerCallback = function(name, ...)
    local requestId = GenerateRequestKey(callbackRequest)
    local response

    callbackRequest[requestId] = function(...)
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

MSK.logging = function(script, code, ...)
    if code == 'error' then
        print(script, '[^1ERROR^0]', ...)
    elseif code == 'debug' then
		print(script, '[^3DEBUG^0]', ...)
	end
end

logging = function(code, ...)
    local script = "[^2"..GetCurrentResourceName().."^0]"
    MSK.logging(script, code, ...)
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
    if callbackRequest[requestId] then 
        callbackRequest[requestId](...)
        callbackRequest[requestId] = nil
    end
end)

RegisterNetEvent("msk_core:notification")
AddEventHandler("msk_core:notification", function(text)
    MSK.Notification(text)
end)

CreateThread(function()
    while true do
        local sleep = 200

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