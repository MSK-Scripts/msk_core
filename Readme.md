# msk_core
Core functions for MSK Scripts

More function will be coming soon...

## Exports
clientside AND serverside
```lua
MSK = exports.msk_core:getCoreObject()
```

## Functions
### COMMON
* Debug and Error Logs
```lua
MSK.logging(script, code, msg, msg2, msg3)

-- example
MSK.logging('[msk_testing]', 'debug', 'Text 1', 'Text 2', 'Text 3')
MSK.logging('[msk_testing]', 'error', 'Text 1', 'Text 2', 'Text 3')
```
* Generate a Random String 
```lua
MSK.GetRandomLetter(length)

-- example
MSK.GetRandomLetter(3) -- abc
string.upper(MSK.GetRandomLetter(3)) -- ABC
```
### CLIENTSIDE
* Trigger Syncron Server Callback
```lua
local data, data2 = MSK.TriggerCallback("Callback_Name", value1, value2, ...)
```
* Timeouts
```lua
-- Add a timeout
timeout = MSK.AddTimeout(miliseconds, function()
    -- waits miliseconds time // asyncron
end)

-- Delete the timeout
MSK.DelTimeout(timeout)
```
### SERVERSIDE
* Register Syncron Server Callback
```lua
MSK.RegisterCallback("Callback_Name", function(source, cb, value1, value2)
    cb(value1, value2)
end)
```
* Discord Webhook *[msk_webhook is NOT required]*
```lua
-- example can be found here: https://github.com/MSK-Scripts/msk_webhook
MSK.AddWebhook(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
```

## Requirements
* oxmysql