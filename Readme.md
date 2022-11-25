# msk_core
Core functions for MSK Scripts

## Exports
clientside AND serverside
```lua
MSK = exports["msk_core"]:getCoreObject()
```

## Functions
### COMMON
* Debug and Error Logs
```lua
MSK.logging(code, msg, msg2, msg3)

-- example
MSK.logging('debug', 'Text 1', 'Text 2', 'Text 3')
MSK.logging('error', 'Text 1', 'Text 2', 'Text 3')
```
### CLIENTSIDE
* Timeouts
```lua
timeout = MSK.AddTimeout(miliseconds, function()
    -- waits miliseconds time // asyncron
end)

MSK.DelTimeout(timeout)
```
* Discord Webhook *[msk_webhook is required]*
```lua
-- example can be found here: https://github.com/MSK-Scripts/msk_webhook
MSK.AddWebhook(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
```
### SERVERSIDE

## Requirements
* oxmysql