MSK = {}
MSK.Timeouts = {}

MSK.AddTimeout = function(ms, cb)
    table.insert(MSK.Timeouts, {time = GetGameTimer() + ms, cb = cb})
    return #MSK.Timeouts
end

MSK.DelTimeout = function(i)
    MSK.Timeouts[i] = nil
end

MSK.AddWebhook = function(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
    exports['msk_webhook']:sendDiscordLog(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
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