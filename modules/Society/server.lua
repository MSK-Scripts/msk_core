local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Society = {}

if IS_CORE then
    ----------------------------------------------------------------------------
    -- Company accounts
    --
    -- Which script owns the company money is a question about the BANKING
    -- resource, not about the framework. A Qbox server can run Renewed-Banking,
    -- a QBCore server can run qb-banking, and ESX has its own addon accounts.
    -- Branching on the framework, as 3.x did, meant every Qbox server got a
    -- hard 0 back no matter what was installed.
    --
    -- The provider is resolved once, on first use, and cached.
    ----------------------------------------------------------------------------
    local provider

    local function esxAccount(society)
        -- esx_addonaccount answers through a callback, synchronously.
        local account

        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. society, function(sharedAccount)
            account = sharedAccount
        end)

        return account
    end

    local providers = {
        {
            name = 'Renewed-Banking',
            available = function() return GetResourceState('Renewed-Banking') == 'started' end,
            get = function(society) return exports['Renewed-Banking']:getAccountMoney(society) or 0 end,
            add = function(society, amount)
                exports['Renewed-Banking']:addAccountMoney(society, amount)
                return true
            end,
            remove = function(society, amount)
                return exports['Renewed-Banking']:removeAccountMoney(society, amount) and true or false
            end,
        },
        {
            name = 'qb-banking',
            available = function() return GetResourceState('qb-banking') == 'started' end,
            get = function(society) return exports['qb-banking']:GetAccountBalance(society) or 0 end,
            add = function(society, amount)
                return exports['qb-banking']:AddMoney(society, amount, 'msk_core') and true or false
            end,
            remove = function(society, amount)
                return exports['qb-banking']:RemoveMoney(society, amount, 'msk_core') and true or false
            end,
        },
        {
            name = 'qb-management',
            available = function() return GetResourceState('qb-management') == 'started' end,
            get = function(society) return exports['qb-management']:GetAccount(society) or 0 end,
            add = function(society, amount)
                exports['qb-management']:AddMoney(society, amount)
                return true
            end,
            remove = function(society, amount)
                return exports['qb-management']:RemoveMoney(society, amount) and true or false
            end,
        },
        {
            name = 'esx_addonaccount',
            available = function()
                return MSK.Bridge.Framework.Type == 'ESX' and GetResourceState('esx_addonaccount') == 'started'
            end,
            get = function(society)
                local account = esxAccount(society)
                return account and (account.money or 0) or 0
            end,
            add = function(society, amount)
                local account = esxAccount(society)
                if not account then return false end

                account.addMoney(amount)
                return true
            end,
            remove = function(society, amount)
                local account = esxAccount(society)
                if not account or (account.money or 0) < amount then return false end

                account.removeMoney(amount)
                return true
            end,
        },
    }

    local function getProvider()
        if provider ~= nil then return provider end

        for i = 1, #providers do
            if providers[i].available() then
                provider = providers[i]

                if Config.Debug then
                    MSK.Logging('info', ('Company accounts handled by ^3%s^0'):format(provider.name))
                end

                return provider
            end
        end

        provider = false
        MSK.Logging('info', 'No supported banking resource found, company account functions return 0.')

        return provider
    end

    ---@param society string society name without the society_ prefix
    ---@return number
    function Society.GetMoney(society)
        if not society then return 0 end

        local active = getProvider()
        return active and active.get(society) or 0
    end
    exports('SocietyGetMoney', Society.GetMoney)

    ---@return boolean
    function Society.AddMoney(society, amount)
        amount = tonumber(amount)
        if not society or not amount or amount <= 0 then return false end

        local active = getProvider()
        return active and active.add(society, math.floor(amount)) or false
    end
    exports('SocietyAddMoney', Society.AddMoney)

    ---@return boolean false when the account does not hold enough
    function Society.RemoveMoney(society, amount)
        amount = tonumber(amount)
        if not society or not amount or amount <= 0 then return false end

        local active = getProvider()
        if not active then return false end

        amount = math.floor(amount)

        -- Check first: not every banking resource refuses an overdraft on its
        -- own, and a society account must not go negative unnoticed.
        if active.get(society) < amount then return false end

        return active.remove(society, amount)
    end
    exports('SocietyRemoveMoney', Society.RemoveMoney)

    ---Which banking resource is being used, or nil when none was found.
    ---@return string|nil
    function Society.GetProvider()
        local active = getProvider()
        return active and active.name or nil
    end
    exports('SocietyGetProvider', Society.GetProvider)

    MSK.Society = Society
    return Society
else
    function Society.GetMoney(...) return exports.msk_core:SocietyGetMoney(...) end
    function Society.AddMoney(...) return exports.msk_core:SocietyAddMoney(...) end
    function Society.RemoveMoney(...) return exports.msk_core:SocietyRemoveMoney(...) end
    function Society.GetProvider(...) return exports.msk_core:SocietyGetProvider(...) end
    return Society
end
