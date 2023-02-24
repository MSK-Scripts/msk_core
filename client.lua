MSK = {}

local Timeouts = {}
local callbackRequest = {}

if Config.Framework:match('esx') then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework:match('qbcore') then
    QBCore = exports['qb-core']:GetCoreObject()
end

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

MSK.Round = function(num, decimal) 
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end

MSK.Trim = function(str, bool)
    if bool then return (str:gsub("^%s*(.-)%s*$", "%1")) end
    return (str:gsub("%s+", ""))
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
    table.insert(Timeouts, {time = GetGameTimer() + ms, cb = cb})
    return #Timeouts
end

MSK.DelTimeout = function(i)
    Timeouts[i] = nil
end

MSK.HasItem = function(item)
    if not Config.Framework:match('esx') or Config.Framework:match('qbcore') then 
        logging('error', ('Function %s can not used without Framework!'):format('MSK.HasItem'))
        return 
    end

    local hasItem = MSK.TriggerCallback('msk_core:hasItem', item)
    return hasItem
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

MSK.Comma = function(int, tag)
    if not tag then tag = '.' end
    local newInt = int

    while true do  
        newInt, k = string.gsub(newInt, "^(-?%d+)(%d%d%d)", '%1'..tag..'%2')

        if (k == 0) then
            break
        end
    end

    return newInt
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

        if #Timeouts > 0 then
            local currTime = GetGameTimer()
            sleep = 0

            for i = 1, #Timeouts, 1 do
                if currTime >= Timeouts[i].time then
                    Timeouts[i].cb()
                    Timeouts[i] = nil
                end
            end
        end

        Wait(sleep)
    end
end)

exports('getCoreObject', function()
    return MSK
end)