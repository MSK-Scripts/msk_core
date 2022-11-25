# msk_core
Core functions for MSK Scripts

## Exports
clientside AND serverside
```lua
MSK = exports["msk_core"]:getCoreObject()
```

## Functions
**CLIENTSIDE**
<details>
    <summary>Timeouts</summary>

    This is for Timeouts.

    ```lua
    timeout = MSK.AddTimeout(miliseconds, function()
        -- waits miliseconds time // asyncron
    end)

    MSK.DelTimeout(handcuffTimerTask)
    ```

</details>

## Requirements
* oxmysql