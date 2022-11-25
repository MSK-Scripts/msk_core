# msk_core
Core functions for MSK Scripts

## Exports
clientside AND serverside
```lua
MSK = exports["msk_core"]:getCoreObject()
```

## Functions
**CLIENTSIDE**
* Timeouts
```lua
timeout = MSK.AddTimeout(miliseconds, function()
    -- waits miliseconds time // asyncron
end)

MSK.DelTimeout(handcuffTimerTask)
```
* Discord Webhook *[msk_webhook is required]*
```lua
MSK.AddWebhook(webhook, botColor, botName, botAvatar, title, description, fields, footer, time)
```

## Requirements
* oxmysql