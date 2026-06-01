local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Society = {}

if IS_CORE then
    local fw = MSK.Bridge.Framework.Type

    ---ESX: resolve the shared society account object synchronously.
    local function esxShared(society)
        local acc
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. society, function(account)
            acc = account
        end)
        return acc
    end

    function Society.GetMoney(society)
        if not society then return 0 end

        if fw == 'ESX' then
            local acc = esxShared(society)
            return acc and (acc.money or 0) or 0
        elseif fw == 'QBCore' then
            if GetResourceState('qb-banking') == 'started' then
                return exports['qb-banking']:GetAccountBalance(society) or 0
            elseif GetResourceState('qb-management') == 'started' then
                return exports['qb-management']:GetAccount(society) or 0
            end
        end

        return 0
    end
    exports('SocietyGetMoney', Society.GetMoney)

    function Society.AddMoney(society, amount)
        amount = tonumber(amount)
        if not society or not amount or amount <= 0 then return false end

        if fw == 'ESX' then
            local acc = esxShared(society)
            if not acc then return false end
            acc.addMoney(math.floor(amount))
            return true
        elseif fw == 'QBCore' then
            if GetResourceState('qb-banking') == 'started' then
                return exports['qb-banking']:AddMoney(society, math.floor(amount), 'msk_banking') and true or false
            elseif GetResourceState('qb-management') == 'started' then
                exports['qb-management']:AddMoney(society, math.floor(amount))
                return true
            end
        end

        return false
    end
    exports('SocietyAddMoney', Society.AddMoney)

    function Society.RemoveMoney(society, amount)
        amount = tonumber(amount)
        if not society or not amount or amount <= 0 then return false end

        if fw == 'ESX' then
            local acc = esxShared(society)
            if not acc then return false end
            if (acc.money or 0) < amount then return false end
            acc.removeMoney(math.floor(amount))
            return true
        elseif fw == 'QBCore' then
            if GetResourceState('qb-banking') == 'started' then
                if (exports['qb-banking']:GetAccountBalance(society) or 0) < amount then return false end
                return exports['qb-banking']:RemoveMoney(society, math.floor(amount), 'msk_banking') and true or false
            elseif GetResourceState('qb-management') == 'started' then
                if (exports['qb-management']:GetAccount(society) or 0) < amount then return false end
                return exports['qb-management']:RemoveMoney(society, math.floor(amount)) and true or false
            end
        end

        return false
    end
    exports('SocietyRemoveMoney', Society.RemoveMoney)

    MSK.Society = Society
    return Society
else
    function Society.GetMoney(...) return exports.msk_core:SocietyGetMoney(...) end
    function Society.AddMoney(...) return exports.msk_core:SocietyAddMoney(...) end
    function Society.RemoveMoney(...) return exports.msk_core:SocietyRemoveMoney(...) end
    return Society
end
