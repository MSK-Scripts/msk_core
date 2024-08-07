MSK = {}

if Config.Framework == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
end

exports('getCoreObject', function()
    return MSK
end)

local RegisteredCommands = {}
MSK.RegisterCommand = function(name, group, cb, console, framework, suggestion)    
    if type(name) == 'table' then
        for k, v in ipairs(name) do 
            MSK.RegisterCommand(v, group, cb, console, framework, suggestion)
        end
        return
    end

    if RegisteredCommands[name] then
        logging('debug', ('Command ^3%s^0 is already registerd. Overriding Command...'):format(name))
    end
    
    local added = addChatSuggestions(name, suggestion)
    while not added do Wait(1) end
    
    RegisteredCommands[name] = {group = group, cb = cb, console = console, suggestion = suggestion}

    RegisterCommand(name, function(source, args, rawCommand)
        local source = source
        local Command, error = RegisteredCommands[name], nil

        if not Command.console and source == 0 then 
            logging('error', 'You can not run this Command in Server Console!')
        else
            if Command.suggestion and Command.suggestion.arguments then 
                local newArgs = {}

                for k, v in ipairs(Command.suggestion.arguments) do 
                    if v.action == 'number' then
                        if args[k] then
                            if tonumber(args[k]) then
                                newArgs[v.name] = args[k]
                            else
                                error = ('Argument %s is not a number!'):format(v.name)
                            end
                        end
                    elseif v.action == 'playerId' then
                        if args[k] then
                            local targetId = args[k]
                            if targetId == 'me' then targetId = source end

                            if tonumber(targetId) > 0 and doesPlayerIdExist(targetId) then
                                newArgs[v.name] = targetId
                            else
                                error = ('PlayerId %s does not exist!'):format(targetId)
                            end
                        end
                    else
                        newArgs[v.name] = args[k]
                    end

                    if not error and not newArgs[v.name] and v.val then 
                        error = ('Argument Mismatch with Argument %s'):format(v.name)
                    end
                    if error then break end
                end

                args = newArgs
            end

            if error then
                if source == 0 then
                    logging('error', error)
                else
                    MSK.Notification(source, error)
                end
            else
                if Config.Framework ~= 'standalone' and framework then
                    local Player = MSK.GetPlayer({source = source})
                    cb(Player, args, rawCommand)
                else
                    cb(source, args, rawCommand)
                end
            end
        end
    end, true)

    if type(group) == 'table' then
        for k, v in ipairs(group) do
            ExecuteCommand(('add_ace group.%s command.%s allow'):format(v, name))
        end
    else
        ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
    end
end
exports('RegisterCommand', MSK.RegisterCommand)

MSK.Notification = function(src, title, message, info, time)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:notification', src, title, message, info, time)
end
MSK.Notify = MSK.Notification
exports('Notification', MSK.Notification)

MSK.AdvancedNotification = function(src, text, title, subtitle, icon, flash, icontype)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:advancedNotification', src, text, title, subtitle, icon, flash, icontype)
end
MSK.AdvancedNotify = MSK.AdvancedNotification
exports('AdvancedNotification', MSK.AdvancedNotification)

MSK.ScaleformAnnounce = function(src, header, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:scaleformNotification', src, header, text, typ, duration)
end
MSK.Scaleform = MSK.ScaleformAnnounce
exports('ScaleformAnnounce', MSK.ScaleformAnnounce)

MSK.Subtitle = function(src, message, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:subtitle', src, message, duration)
end
exports('Subtitle', MSK.Subtitle)

MSK.Spinner = function(src, text, typ, duration)
    if not src or src == 0 then return end
    TriggerClientEvent('msk_core:spinner', src, text, typ, duration)
end
exports('Spinner', MSK.Spinner)

MSK.AddWebhook = function(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
    local content = {}

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

    if fields then
        content = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = botColor,
            ["fields"] = fields,
            ["footer"] = footer
        }}
    else
        content = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = botColor,
            ["footer"] = footer
        }}
    end

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = botName,
        embeds = content,
        avatar_url = botAvatar
    }), {
        ['Content-Type'] = 'application/json'
    })
end
exports('AddWebhook', MSK.AddWebhook)

MSK.HasItem = function(Player, item)
    if not Player then logging('error', 'Player on Function MSK.HasItem does not exist!') return end
    if Config.Framework == 'standalone' then 
        return logging('error', ('Function %s can not used without Framework!'):format('^3MSK.HasItem^0'))
    end
    local hasItem

    if Config.Framework == 'esx' then
        hasItem = Player.hasItem(item)
    elseif Config.Framework == 'qbcore' then
        hasItem = Player.Functions.GetItemByName(item)
    end

    return hasItem
end
exports('HasItem', MSK.HasItem)

doesPlayerIdExist = function(playerId)
    for k, id in pairs(GetPlayers()) do
        if id == playerId then
            return true
        end
    end
    return false
end

addChatSuggestions = function(name, suggestion)
    if RegisteredCommands[name] then
        if RegisteredCommands[name].suggestion then
            TriggerClientEvent('chat:removeSuggestion', -1, '/' .. name)
        end
    end

    if suggestion then
        if not suggestion.arguments then suggestion.arguments = {} end
        if not suggestion.help then suggestion.help = '' end
    
        TriggerClientEvent('chat:addSuggestion', -1, '/' .. name, suggestion.help, suggestion.arguments)
    end

    return true
end

GithubUpdater = function()
    local GetCurrentVersion = function()
	    return GetResourceMetadata(GetCurrentResourceName(), "version")
    end

	local isVersionIncluded = function(Versions, cVersion)
		for k, v in pairs(Versions) do
			if v.version == cVersion then
				return true
			end
		end

		return false
	end
    
    local CurrentVersion = GetCurrentVersion()
    local resourceName = "^0[^2"..GetCurrentResourceName().."^0]"

    if Config.VersionChecker then
        PerformHttpRequest('https://raw.githubusercontent.com/Musiker15/VERSIONS/main/Lib.json', function(errorCode, jsonString, headers)
			if not jsonString then 
                print(resourceName .. '^1 Update Check failed ^3Please Update to the latest Version:^9 https://github.com/MSK-Scripts/msk_core/ ^0')
                print(resourceName .. '^2 ✓ Resource loaded^0 - ^5Current Version: ^0' .. CurrentVersion)
                return 
            end

			local decoded = json.decode(jsonString)
            local version = decoded[1].version

            if CurrentVersion == version then
                print(resourceName .. '^2 ✓ Resource is Up to Date^0 - ^5Current Version: ^2' .. CurrentVersion .. '^0')
            elseif CurrentVersion ~= version then
                print(resourceName .. '^1 ✗ Resource Outdated. Please Update!^0 - ^5Current Version: ^1' .. CurrentVersion .. '^0')
                print('^5Latest Version: ^2' .. version .. '^0 - ^6Download here:^9 https://github.com/MSK-Scripts/msk_core/releases/tag/v'.. version .. '^0')
				print('')
				for i=1, #decoded do 
					if decoded[i]['version'] == CurrentVersion then
						break
					elseif not isVersionIncluded(decoded, CurrentVersion) then
						print('^1You are using an^3 UNSUPPORTED VERSION^1 of ^0' .. resourceName)
						break
					end

					if decoded[i]['changelogs'] then
						print('^3Changelogs v' .. decoded[i]['version'] .. '^0')

						for _, c in ipairs(decoded[i]['changelogs']) do
							print(c)
						end
					end
				end
            end
        end)
    else
        print(resourceName .. '^2 ✓ Resource loaded^0 - ^5Current Version: ^2' .. CurrentVersion .. '^0')
    end
end
GithubUpdater()

checkResourceName = function()
    if GetCurrentResourceName() ~= 'msk_core' then
        while true do
            print('^1Please rename the Script to^3 msk_core^0!')
            Wait(5000)
        end
    end
end
checkResourceName()