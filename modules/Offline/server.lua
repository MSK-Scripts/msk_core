local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Offline = {}

if IS_CORE then
    local fw = MSK.Bridge.Framework.Type

    -- table / id-column / json-column per framework
    --
    -- Qbox uses the same players table as QBCore: citizenid as the primary key
    -- and money as a JSON text column. Verified against qbx_core.sql 1.24.0.
    local map = {
        ESX    = { tbl = 'users',   idCol = 'identifier', jsonCol = 'accounts' },
        QBCore = { tbl = 'players', idCol = 'citizenid',  jsonCol = 'money'    },
        Qbox   = { tbl = 'players', idCol = 'citizenid',  jsonCol = 'money'    },
    }

    ---Where the framework keeps its characters. Scripts that add their own
    ---column to that table need the name and the key column, and guessing
    ---'users' works on exactly one of the three frameworks.
    ---@return table|nil { table = string, identifier = string }
    function Offline.GetPlayerTable()
        local m = map[fw]
        if not m then return nil end

        return { table = m.tbl, identifier = m.idCol }
    end
    exports('GetPlayerTable', Offline.GetPlayerTable)

    function Offline.GetBank(identifier)
        local m = map[fw]
        if not m or not identifier then return nil end

        local raw = MySQL.scalar.await(('SELECT `%s` FROM `%s` WHERE `%s` = ?'):format(m.jsonCol, m.tbl, m.idCol), { identifier })
        if not raw then return nil end

        local ok, decoded = pcall(json.decode, raw)
        if not ok or type(decoded) ~= 'table' then return nil end
        return tonumber(decoded.bank) or 0
    end
    exports('OfflineGetBank', Offline.GetBank)

    function Offline.AddBank(identifier, amount)
        local m = map[fw]
        amount = tonumber(amount)
        if not m or not identifier or not amount or amount <= 0 then return false end

        local affected = MySQL.update.await(
            ('UPDATE `%s` SET `%s` = JSON_SET(`%s`, "$.bank", COALESCE(JSON_EXTRACT(`%s`, "$.bank"), 0) + ?) WHERE `%s` = ?')
                :format(m.tbl, m.jsonCol, m.jsonCol, m.jsonCol, m.idCol),
            { math.floor(amount), identifier }
        )
        return (affected or 0) > 0
    end
    exports('OfflineAddBank', Offline.AddBank)

    function Offline.RemoveBank(identifier, amount)
        local m = map[fw]
        amount = tonumber(amount)
        if not m or not identifier or not amount or amount <= 0 then return false end

        -- Atomic: only deduct if sufficient funds (WHERE guard).
        local affected = MySQL.update.await(
            ('UPDATE `%s` SET `%s` = JSON_SET(`%s`, "$.bank", JSON_EXTRACT(`%s`, "$.bank") - ?) WHERE `%s` = ? AND COALESCE(JSON_EXTRACT(`%s`, "$.bank"), 0) >= ?')
                :format(m.tbl, m.jsonCol, m.jsonCol, m.jsonCol, m.idCol, m.jsonCol),
            { math.floor(amount), identifier, math.floor(amount) }
        )
        return (affected or 0) > 0
    end
    exports('OfflineRemoveBank', Offline.RemoveBank)

    MSK.Offline = Offline
    return Offline
else
    function Offline.GetPlayerTable(...) return exports.msk_core:GetPlayerTable(...) end
    function Offline.GetBank(...) return exports.msk_core:OfflineGetBank(...) end
    function Offline.AddBank(...) return exports.msk_core:OfflineAddBank(...) end
    function Offline.RemoveBank(...) return exports.msk_core:OfflineRemoveBank(...) end
    return Offline
end
