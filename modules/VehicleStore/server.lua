local IS_CORE = GetCurrentResourceName() == 'msk_core'
local VehicleStore = {}

--------------------------------------------------------------------------------
-- Owned vehicles, one shape across frameworks
--
-- The frameworks disagree about more than the table name:
--
--   ESX   owned_vehicles    owner = identifier, `vehicle` holds ALL properties
--                           as JSON, `stored` is 0/1, and it has `type` and
--                           `job` columns.
--   QB    player_vehicles   citizenid + license, `vehicle` holds the SPAWN NAME,
--   Qbox                    the properties live in `mods`, `hash` holds the
--                           model hash, and `state` is 0 out / 1 garage /
--                           2 impound. There is no type and no job column.
--
-- Reading a row therefore means different work per framework, which is why
-- every script that touched owned vehicles carried its own copy of it, usually
-- for ESX only.
--
-- The two missing columns are added on start with ALTER TABLE ... IF NOT
-- EXISTS. That is additive, keeps existing rows untouched, and is the same
-- approach msk_enginetoggle already uses for its alarmStage column.
--------------------------------------------------------------------------------
if not IS_CORE then
    function VehicleStore.GetByPlate(...) return exports.msk_core:VehicleGetByPlate(...) end
    function VehicleStore.Insert(...) return exports.msk_core:VehicleInsert(...) end
    function VehicleStore.Delete(...) return exports.msk_core:VehicleDelete(...) end
    function VehicleStore.Update(...) return exports.msk_core:VehicleUpdate(...) end
    function VehicleStore.GetSchema(...) return exports.msk_core:VehicleGetSchema(...) end
    function VehicleStore.CountByPlate(...) return exports.msk_core:VehicleCountByPlate(...) end
    function VehicleStore.ClearJob(...) return exports.msk_core:VehicleClearJob(...) end
    function VehicleStore.Browse(...) return exports.msk_core:VehicleBrowse(...) end

    return VehicleStore
end

local framework = MSK.Bridge.Framework.Type

--------------------------------------------------------------------------------
-- Schema
--
-- `props` names the column holding the property JSON, `model` the column
-- holding something the game can spawn (a hash on ESX, a spawn name elsewhere).
--------------------------------------------------------------------------------
local schemas = {
    ESX = {
        table     = 'owned_vehicles',
        owner     = 'owner',
        plate     = 'plate',
        props     = 'vehicle',
        model     = nil,            -- lives inside the props JSON
        stored    = 'stored',
        garage    = 'garage',
        type      = 'type',
        job       = 'job',
        storedIn  = 1,              -- value that means "in the garage"
        storedOut = 0,

        -- For Browse(): the character table and how to build a full name from
        -- it. ESX keeps first and last name in their own columns.
        users     = 'users',
        usersKey  = 'identifier',
        nameSql   = "CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.lastname,''))",
    },
    QBCore = {
        table     = 'player_vehicles',
        owner     = 'citizenid',
        plate     = 'plate',
        props     = 'mods',
        model     = 'vehicle',
        hash      = 'hash',
        stored    = 'state',
        garage    = 'garage',
        type      = 'type',         -- added by ensureColumns()
        job       = 'job',          -- added by ensureColumns()
        storedIn  = 1,
        storedOut = 0,

        -- QB and Qbox keep the character name as JSON in `charinfo`, so the
        -- name has to be extracted before it can be compared.
        users     = 'players',
        usersKey  = 'citizenid',
        nameSql   = "CONCAT(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(u.charinfo,'$.firstname')),''),' '," ..
                    "IFNULL(JSON_UNQUOTE(JSON_EXTRACT(u.charinfo,'$.lastname')),''))",
    },
}

schemas.Qbox = schemas.QBCore

local schema = schemas[framework]

function VehicleStore.GetSchema()
    -- A copy, so a consumer cannot rewrite the schema for everyone else.
    if not schema then return nil end

    local copy = {}
    for key, value in pairs(schema) do copy[key] = value end

    return copy
end
exports('VehicleGetSchema', VehicleStore.GetSchema)

--------------------------------------------------------------------------------
-- Missing columns
--------------------------------------------------------------------------------
local function ensureColumns()
    if not schema or framework == 'ESX' then return end

    -- Only QB and Qbox are missing these two.
    local ok, err = pcall(function()
        MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS `job` VARCHAR(50) DEFAULT NULL"):format(schema.table))
        MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS `type` VARCHAR(20) DEFAULT NULL"):format(schema.table))
    end)

    if not ok then
        MSK.Logging('error', ('Could not add the job/type columns to %s: %s'):format(schema.table, err))
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not schema then return end

    CreateThread(function()
        Wait(1000)
        ensureColumns()
    end)
end)

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------
local function decode(value)
    if type(value) ~= 'string' then
        return type(value) == 'table' and value or nil
    end

    local ok, decoded = pcall(json.decode, value)
    return ok and type(decoded) == 'table' and decoded or nil
end

---Turns a database row into the unified shape.
---@return table|nil
local function readRow(row)
    if not row then return nil end

    local props = decode(row[schema.props])
    local model

    if framework == 'ESX' then
        -- ESX keeps the model inside the JSON, usually as a hash, sometimes as
        -- a spawn name.
        model = props and props.model
    else
        model = row[schema.model]

        if row.hash and tonumber(row.hash) then
            props = props or {}
            props.model = props.model or tonumber(row.hash)
        end
    end

    return {
        plate    = row[schema.plate],
        owner    = row[schema.owner],
        model    = model,
        props    = props or {},
        stored   = tonumber(row[schema.stored]) == schema.storedIn,
        garage   = row[schema.garage],
        type     = row[schema.type],
        job      = row[schema.job],
        raw      = row,
    }
end
VehicleStore.ReadRow = readRow

---@param plate string
---@return table|nil unified vehicle, nil when the plate is unknown
function VehicleStore.GetByPlate(plate)
    if not schema or not plate then return nil end

    plate = MSK.String.Trim(tostring(plate))

    -- Plates are stored space padded by some scripts, so match both forms.
    local row = MySQL.single.await(
        ("SELECT * FROM `%s` WHERE `%s` = ? OR TRIM(`%s`) = ? LIMIT 1"):format(schema.table, schema.plate, schema.plate),
        { plate, plate }
    )

    return readRow(row)
end
exports('VehicleGetByPlate', VehicleStore.GetByPlate)

---@param plate string
---@return integer how many rows carry this plate
function VehicleStore.CountByPlate(plate)
    if not schema or not plate then return 0 end

    plate = MSK.String.Trim(tostring(plate))

    return MySQL.scalar.await(
        ("SELECT COUNT(*) FROM `%s` WHERE `%s` = ? OR TRIM(`%s`) = ?"):format(schema.table, schema.plate, schema.plate),
        { plate, plate }
    ) or 0
end
exports('VehicleCountByPlate', VehicleStore.CountByPlate)

--------------------------------------------------------------------------------
-- Writing
--------------------------------------------------------------------------------
---@param data table { owner, plate, model, props, stored?, garage?, type?, job?, license? }
---@return boolean
function VehicleStore.Insert(data)
    if not schema or type(data) ~= 'table' then return false end
    if not data.owner or not data.plate then return false end

    local plate = MSK.String.Trim(tostring(data.plate))
    local props = type(data.props) == 'table' and data.props or {}

    local columns = { schema.owner, schema.plate, schema.props, schema.stored }
    local values = { data.owner, plate, json.encode(props), data.stored == false and schema.storedOut or schema.storedIn }

    if framework == 'ESX' then
        -- The model has to be inside the JSON, that is where ESX looks.
        props.model = props.model or data.model
        values[3] = json.encode(props)
    else
        -- QB and Qbox want the spawn name in its own column and the hash beside
        -- it. Without the hash their garages cannot spawn the vehicle.
        local model = data.model
        local hash = tonumber(model) or (type(model) == 'string' and joaat(model)) or props.model

        columns[#columns + 1] = schema.model
        values[#values + 1] = type(model) == 'string' and model or tostring(model)

        columns[#columns + 1] = schema.hash
        values[#values + 1] = hash

        if data.license then
            columns[#columns + 1] = 'license'
            values[#values + 1] = data.license
        end
    end

    for _, key in ipairs({ 'garage', 'type', 'job' }) do
        if data[key] ~= nil and data[key] ~= '' then
            columns[#columns + 1] = schema[key]
            values[#values + 1] = data[key]
        end
    end

    local placeholders = {}
    local quoted = {}

    for index = 1, #columns do
        placeholders[index] = '?'
        quoted[index] = ('`%s`'):format(columns[index])
    end

    local ok, err = pcall(function()
        MySQL.insert.await(
            ("INSERT INTO `%s` (%s) VALUES (%s)"):format(
                schema.table, table.concat(quoted, ', '), table.concat(placeholders, ', ')
            ),
            values
        )
    end)

    if not ok then
        MSK.Logging('error', ('Could not store vehicle %s: %s'):format(plate, err))
        return false
    end

    return true
end
exports('VehicleInsert', VehicleStore.Insert)

---@param plate string
---@return boolean true when a row was actually removed
function VehicleStore.Delete(plate)
    if not schema or not plate then return false end

    plate = MSK.String.Trim(tostring(plate))

    local affected = MySQL.update.await(
        ("DELETE FROM `%s` WHERE `%s` = ? OR TRIM(`%s`) = ?"):format(schema.table, schema.plate, schema.plate),
        { plate, plate }
    )

    return (affected or 0) > 0
end
exports('VehicleDelete', VehicleStore.Delete)

---Updates single fields. Keys are the unified names (owner, garage, type, job,
---stored, props), not the column names of whichever framework is running.
---@param plate string
---@param fields table
---@return boolean
function VehicleStore.Update(plate, fields)
    if not schema or not plate or type(fields) ~= 'table' then return false end

    plate = MSK.String.Trim(tostring(plate))

    local assignments, values = {}, {}

    for key, value in pairs(fields) do
        local column = schema[key]

        if column then
            if key == 'stored' then
                value = value and schema.storedIn or schema.storedOut
            elseif key == 'props' and type(value) == 'table' then
                value = json.encode(value)
            end

            assignments[#assignments + 1] = ('`%s` = ?'):format(column)
            values[#values + 1] = value
        end
    end

    if #assignments == 0 then return false end

    values[#values + 1] = plate
    values[#values + 1] = plate

    local affected = MySQL.update.await(
        ("UPDATE `%s` SET %s WHERE `%s` = ? OR TRIM(`%s`) = ?"):format(
            schema.table, table.concat(assignments, ', '), schema.plate, schema.plate
        ),
        values
    )

    return (affected or 0) > 0
end
exports('VehicleUpdate', VehicleStore.Update)

--------------------------------------------------------------------------------
-- Browse
--
-- Paginated and filtered in SQL, so it stays usable on a table with thousands
-- of rows. The name search joins the character table, which is `users` on ESX
-- and `players` on QB and Qbox, with the name in a JSON column there.
--
-- If that join fails (a table or column a server does not have), the query is
-- retried without it rather than returning nothing.
--------------------------------------------------------------------------------
---@param opts table { page?, perPage?, query?, garage?, type?, model?, job?, owner? }
---@return table { total = integer, page = integer, vehicles = table[] }
function VehicleStore.Browse(opts)
    if not schema then return { total = 0, page = 1, vehicles = {} } end

    opts = type(opts) == 'table' and opts or {}

    local page = math.max(1, math.floor(tonumber(opts.page) or 1))
    local perPage = math.min(100, math.max(1, math.floor(tonumber(opts.perPage) or 25)))
    local offset = (page - 1) * perPage
    local query = type(opts.query) == 'string' and MSK.String.Trim(opts.query) or ''

    local function build(withUsers)
        local where, params = {}, {}

        if #query > 0 then
            local like = '%' .. query .. '%'

            if withUsers then
                where[#where + 1] = ("(v.`%s` LIKE ? OR v.`%s` LIKE ? OR %s LIKE ?)")
                    :format(schema.plate, schema.owner, schema.nameSql)
                params[#params + 1] = like
                params[#params + 1] = like
                params[#params + 1] = like
            else
                where[#where + 1] = ("(v.`%s` LIKE ? OR v.`%s` LIKE ?)"):format(schema.plate, schema.owner)
                params[#params + 1] = like
                params[#params + 1] = like
            end
        end

        for key, column in pairs({ garage = schema.garage, type = schema.type, job = schema.job, owner = schema.owner }) do
            local value = opts[key]

            if type(value) == 'string' and #value > 0 then
                where[#where + 1] = ("v.`%s` = ?"):format(column)
                params[#params + 1] = value
            end
        end

        if type(opts.model) == 'string' and #opts.model > 0 then
            if schema.hash then
                -- QB and Qbox store the hash in its own column, so this is an
                -- exact comparison instead of a scan through JSON.
                local hash = joaat(opts.model)
                where[#where + 1] = ("(v.`%s` = ? OR v.`%s` = ?)"):format(schema.hash, schema.model)
                params[#params + 1] = hash
                params[#params + 1] = opts.model
            else
                -- ESX keeps the model inside the JSON, and depending on the
                -- version as a signed or unsigned 32 bit value, so match both.
                local hash = joaat(opts.model)
                local unsigned = (hash < 0) and (hash + 4294967296) or hash

                where[#where + 1] = ("(v.`%s` LIKE ? OR v.`%s` LIKE ?)"):format(schema.props, schema.props)
                params[#params + 1] = '%"model":' .. hash .. '%'
                params[#params + 1] = '%"model":' .. unsigned .. '%'
            end
        end

        return (#where > 0) and (' WHERE ' .. table.concat(where, ' AND ')) or '', params
    end

    local function run(withUsers)
        local whereSql, params = build(withUsers)
        local join = withUsers
            and (" LEFT JOIN `%s` u ON u.`%s` = v.`%s`"):format(schema.users, schema.usersKey, schema.owner)
            or ''

        local total = MySQL.scalar.await(
            ("SELECT COUNT(*) FROM `%s` v%s%s"):format(schema.table, join, whereSql), params
        ) or 0

        local rows = MySQL.query.await(
            ("SELECT v.*%s FROM `%s` v%s%s ORDER BY v.`%s` LIMIT %d OFFSET %d"):format(
                withUsers and (', ' .. schema.nameSql .. ' AS ownerName') or '',
                schema.table, join, whereSql, schema.plate, perPage, offset
            ), params
        ) or {}

        return total, rows
    end

    local ok, total, rows = pcall(run, true)

    if not ok then
        ok, total, rows = pcall(run, false)

        if not ok then
            MSK.Logging('error', ('Vehicle browse failed: %s'):format(total))
            return { total = 0, page = page, vehicles = {} }
        end
    end

    local vehicles = {}

    for index = 1, #rows do
        local vehicle = readRow(rows[index])

        if vehicle then
            vehicle.ownerName = rows[index].ownerName
            vehicles[#vehicles + 1] = vehicle
        end
    end

    return { total = total, page = page, perPage = perPage, vehicles = vehicles }
end
exports('VehicleBrowse', VehicleStore.Browse)

---Writes a real NULL into the job column.
---Update() skips nil values, because a nil in a parameter list collapses it,
---so clearing a column needs its own call.
---@param plate string
---@return boolean
function VehicleStore.ClearJob(plate)
    if not schema or not plate then return false end

    plate = MSK.String.Trim(tostring(plate))

    local affected = MySQL.update.await(
        ("UPDATE `%s` SET `%s` = NULL WHERE `%s` = ? OR TRIM(`%s`) = ?"):format(
            schema.table, schema.job, schema.plate, schema.plate
        ),
        { plate, plate }
    )

    return (affected or 0) > 0
end
exports('VehicleClearJob', VehicleStore.ClearJob)

MSK.VehicleStore = VehicleStore

return VehicleStore
