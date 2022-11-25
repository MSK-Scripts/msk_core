if Config.testCommand.enable then
    RegisterCommand(Config.testCommand.command, function(source, args, rawCommand)
        exports['msk_webhook']:sendDiscordLog(Config.Webhook.webhook, Config.Webhook.botColor, Config.Webhook.botName, Config.Webhook.botAvatar, Config.Webhook.title, Config.Webhook.description, Config.Webhook.fields, Config.Webhook.footer, Config.Webhook.time)
    end)
end

exports('sendDiscordLog', function(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
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
end)

---- GitHub Updater ----
function GetCurrentVersion()
	return GetResourceMetadata( GetCurrentResourceName(), "version" )
end

local CurrentVersion = GetCurrentVersion()
local resourceName = "^4["..GetCurrentResourceName().."]^0"

if Config.VersionChecker then
	PerformHttpRequest('https://raw.githubusercontent.com/MSK-Scripts/msk_webhook/main/VERSION', function(Error, NewestVersion, Header)
		print("###############################")
    	if CurrentVersion == NewestVersion then
	    	print(resourceName .. '^2 ✓ Resource is Up to Date^0 - ^5Current Version: ^2' .. CurrentVersion .. '^0')
    	elseif CurrentVersion ~= NewestVersion then
        	print(resourceName .. '^1 ✗ Resource Outdated. Please Update!^0 - ^5Current Version: ^1' .. CurrentVersion .. '^0')
	    	print('^5Newest Version: ^2' .. NewestVersion .. '^0 - ^6Download here: ^9https://github.com/MSK-Scripts/msk_webhook/releases/tag/v'.. NewestVersion .. '^0')
    	end
		print("###############################")
	end)
else
	print("###############################")
	print(resourceName .. '^2 ✓ Resource loaded^0')
	print("###############################")
end