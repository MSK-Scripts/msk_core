MSK = {}

local Callbacks = {}
local Letters = {}
for i = 48,  57 do table.insert(Letters, string.char(i)) end
for i = 65,  90 do table.insert(Letters, string.char(i)) end
for i = 97, 122 do table.insert(Letters, string.char(i)) end

MSK.GetRandomLetter = function(length)
    Wait(0)
    if length > 0 then
        return GetRandomLetter(length - 1) .. Letters[math.random(1, #Letters)]
    else
        return ''
    end
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
end

MSK.AddWebhook = function(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
    if footer then 
        if time then
            footer = {
                ["text"] = footer.text .. " • " .. os.date(time),
                ["icon_url"] = footer.link
            }
        else
            footer = {
                ["text"] = footer.text,
                ["icon_url"] = footer.link
            }
        end
    end

    local content = {{
        ["title"] = title,
        ["description"] = description,
        ["color"] = botColor,
        ["fields"] = fields,
        ["footer"] = footer
    }}

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = botName,
        embeds = content,
        avatar_url = botAvatar
    }), {
        ['Content-Type'] = 'application/json'
    })
end

MSK.RegisterCallback = function(name, cb)
    Callbacks[name] = cb
end

MSK.logging = function(script, code, msg, msg2, msg3)
    if code == 'error' then
        if msg3 then
			print(script, '[^1ERROR^0]', msg, msg2, msg3)
        elseif msg2 and not msg3 then
            print(script, '[^1ERROR^0]', msg, msg2)
        else
		    print(script, '[^1ERROR^0]', msg)
        end
    elseif code == 'debug' then
		if msg3 then
			print(script, '[^3DEBUG^0]', msg, msg2, msg3)
        elseif msg2 and not msg3 then
            print(script, '[^3DEBUG^0]', msg, msg2)
        else
		    print(script, '[^3DEBUG^0]', msg)
        end
	end
end

RegisterNetEvent('msk_core:triggerCallback')
AddEventHandler('msk_core:triggerCallback', function(name, requestId, ...)
    local src = source
    if Callbacks[name] then
        Callbacks[name](src, function(...)
            TriggerClientEvent("msk_core:responseCallback", src, requestId, ...)
        end, ...)
    end
end)

GithubUpdater = function()
    GetCurrentVersion = function()
	    return GetResourceMetadata( GetCurrentResourceName(), "version" )
    end
    
    local CurrentVersion = GetCurrentVersion()
    local resourceName = "^4["..GetCurrentResourceName().."]^0"

    if Config.VersionChecker then
        PerformHttpRequest('https://raw.githubusercontent.com/MSK-Scripts/msk_core/main/VERSION', function(Error, NewestVersion, Header)
            print("###############################")
            if CurrentVersion == NewestVersion then
                print(resourceName .. '^2 ✓ Resource is Up to Date^0 - ^5Current Version: ^2' .. CurrentVersion .. '^0')
            elseif CurrentVersion ~= NewestVersion then
                print(resourceName .. '^1 ✗ Resource Outdated. Please Update!^0 - ^5Current Version: ^1' .. CurrentVersion .. '^0')
                print('^5Newest Version: ^2' .. NewestVersion .. '^0 - ^6Download here:^9 https://github.com/MSK-Scripts/msk_core ^0')
            end
            print("###############################")
        end)
    else
        print("###############################")
        print(resourceName .. '^2 ✓ Resource loaded^0')
        print("###############################")
    end
end
GithubUpdater()

exports('getCoreObject', function()
    return MSK
end)