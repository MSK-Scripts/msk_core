--------------------------------------------------------------------------------
-- MSK.Logger (server)
--
-- Ships log entries to an external log service in batches. Nothing is sent
-- until a service is configured, so the module is free when unused.
--
--   MSK.Logger.Log(source, 'shop:purchase', 'Bought a pistol', { price = 2500 })
--   MSK.Logger.Log(source, 'shop:purchase', 'Bought a pistol', nil, 'shop:ammunation,item:pistol')
--
-- `tags` are key:value pairs, as a string 'a:1,b:2', a list { 'a:1' } or a
-- table { a = 1 }. For a player the name and every identifier except the IP
-- address are added.
--
-- Configuration lives in convars (server.cfg), so keys never sit in a script:
--
--   set msk:logger "loki"                        -- or "datadog", "fivemanage"
--   set msk:logger:service "my-server"           -- optional, default "fivem"
--   set msk:logger:hostname "server-1"           -- optional, default sv_projectName
--
--   Grafana Loki
--   set msk:loki:endpoint "https://loki.example.com"   -- https:// is added when missing
--   set msk:loki:user "user"                     -- optional, basic auth
--   set msk:loki:password "secret"               -- optional, basic auth
--   set msk:loki:tenant "tenant-id"              -- optional, X-Scope-OrgID
--
--   Datadog
--   set msk:datadog:key "api-key"
--   set msk:datadog:site "datadoghq.eu"          -- optional, default datadoghq.com
--
--   Fivemanage
--   set msk:fivemanage:key "api-key"
--   set msk:fivemanage:dataset "my-dataset"      -- optional
--
-- Use `set`, never `setr`: setr replicates a convar to every client, and with
-- it the API key.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Logger = {}

if IS_CORE then
    local FLUSH_INTERVAL = 1000
    local FLUSH_SIZE = 50

    -- Game colour codes: ~r~, ^1 and ^#ff0000.
    local function stripColors(text)
        return (tostring(text):gsub('~%a~', ''):gsub('%^#%x%x%x%x%x%x', ''):gsub('%^%d', ''))
    end

    local serviceName = GetConvar('msk:logger', ''):lower()
    local serviceLabel = GetConvar('msk:logger:service', 'fivem')
    local hostname = GetConvar('msk:logger:hostname', '')

    if hostname == '' then
        hostname = stripColors(GetConvar('sv_projectName', 'fxserver'))
    end

    local queue, size = {}, 0

    local ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    local function base64(input)
        local out = {}

        for i = 1, #input, 3 do
            local a, b, c = input:byte(i, i + 2)
            local chunk = (a << 16) | ((b or 0) << 8) | (c or 0)

            local s1 = (chunk >> 18) & 63
            local s2 = (chunk >> 12) & 63
            local s3 = (chunk >> 6) & 63
            local s4 = chunk & 63

            out[#out + 1] = ALPHABET:sub(s1 + 1, s1 + 1)
                .. ALPHABET:sub(s2 + 1, s2 + 1)
                .. (b and ALPHABET:sub(s3 + 1, s3 + 1) or '=')
                .. (c and ALPHABET:sub(s4 + 1, s4 + 1) or '=')
        end

        return table.concat(out)
    end

    local function tagValue(value)
        return (tostring(value):gsub('[,%s]', '_'))
    end

    -- Entries are encoded one by one. A single entry that JSON cannot encode
    -- (a function or userdata in `extra`) made the whole batch fail, and up to
    -- 50 entries were lost with it.
    local function encodable(value)
        local ok, encoded = pcall(json.encode, value)
        return ok and encoded or nil
    end

    local function reportSkipped(count)
        if count > 0 then
            MSK.Logging('warn', ('MSK.Logger: %s entries could not be encoded as JSON and were skipped.'):format(count))
        end
    end

    local function onResponse(service)
        return function(status, _, _, errorText)
            if status < 200 or status >= 300 then
                MSK.Logging('warn', ('MSK.Logger: %s answered with HTTP %s %s'):format(service, status, errorText or ''))
            end
        end
    end

    --------------------------------------------------------------------------
    -- Tags and player data
    --------------------------------------------------------------------------
    local function parseTags(tags)
        local parsed = {}
        local kind = type(tags)

        local function addPair(text)
            local key, value = tostring(text):match('^%s*([^:]+):(.-)%s*$')
            if key then parsed[key] = value end
        end

        if kind == 'string' then
            for part in tags:gmatch('[^,]+') do addPair(part) end
        elseif kind == 'table' then
            for key, value in pairs(tags) do
                if type(key) == 'number' then
                    addPair(value)
                else
                    parsed[tostring(key)] = tostring(value)
                end
            end
        end

        return next(parsed) and parsed or nil
    end

    -- Read once per player and kept until the player leaves.
    local playerInfo = {}

    local function getPlayerInfo(playerId)
        local info = playerInfo[playerId]
        if info then return info end

        local identifiers = {}

        for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
            local identifier = GetPlayerIdentifier(playerId, i)

            -- The IP address stays out of external logs.
            if identifier and not identifier:find('^ip:') then
                identifiers[#identifiers + 1] = identifier
            end
        end

        info = {
            name = stripColors(GetPlayerName(playerId) or ''),
            license = GetPlayerIdentifierByType(playerId, 'license'),
            identifiers = identifiers,
        }

        playerInfo[playerId] = info
        return info
    end

    AddEventHandler('playerDropped', function()
        local playerId = tonumber(source)
        if playerId then playerInfo[playerId] = nil end
    end)

    --------------------------------------------------------------------------
    -- Loki
    --------------------------------------------------------------------------
    local function lokiEndpoint()
        local endpoint = GetConvar('msk:loki:endpoint', ''):gsub('/+$', '')

        -- Without a scheme PerformHttpRequest failed on every batch.
        if endpoint ~= '' and not endpoint:find('^https?://') then
            endpoint = 'https://' .. endpoint
        end

        return endpoint
    end

    local function sendLoki(entries)
        local endpoint = lokiEndpoint()
        local user = GetConvar('msk:loki:user', '')
        local password = GetConvar('msk:loki:password', '')
        local tenant = GetConvar('msk:loki:tenant', '')

        -- One stream per label combination. Loki wants the lines of a stream in
        -- chronological order, which the queue already is.
        local streams, list = {}, {}
        local skipped = 0

        for i = 1, #entries do
            local entry = entries[i]

            local line = encodable({
                message = entry.message,
                player = entry.player,
                identifier = entry.identifier,
                identifiers = entry.identifiers,
                source = entry.source,
                tags = entry.tags,
                extra = entry.extra,
            })

            if not line then
                skipped = skipped + 1
            else
                local key = entry.resource .. '\0' .. entry.event
                local stream = streams[key]

                if not stream then
                    stream = {
                        stream = {
                            service = serviceLabel,
                            server = hostname,
                            resource = entry.resource,
                            event = entry.event,
                        },
                        values = {},
                    }
                    streams[key] = stream
                    list[#list + 1] = stream
                end

                stream.values[#stream.values + 1] = { ('%d000000000'):format(entry.timestamp), line }
            end
        end

        reportSkipped(skipped)
        if #list == 0 then return end

        local headers = { ['Content-Type'] = 'application/json' }

        if user ~= '' then
            headers['Authorization'] = 'Basic ' .. base64(user .. ':' .. password)
        end

        if tenant ~= '' then
            headers['X-Scope-OrgID'] = tenant
        end

        PerformHttpRequest(endpoint .. '/loki/api/v1/push', onResponse('Loki'), 'POST', json.encode({ streams = list }), headers)
    end

    --------------------------------------------------------------------------
    -- Datadog
    --------------------------------------------------------------------------
    local function sendDatadog(entries)
        local key = GetConvar('msk:datadog:key', '')
        local site = GetConvar('msk:datadog:site', 'datadoghq.com')

        local items = {}
        local skipped = 0

        for i = 1, #entries do
            local entry = entries[i]
            local tags = ('resource:%s,event:%s'):format(tagValue(entry.resource), tagValue(entry.event))

            if entry.identifier then
                tags = tags .. ',identifier:' .. tagValue(entry.identifier)
            end

            if entry.tags then
                for tagKey, value in pairs(entry.tags) do
                    tags = tags .. (',%s:%s'):format(tagValue(tagKey), tagValue(value))
                end
            end

            local item = {
                ddsource = 'fivem',
                service = serviceLabel,
                hostname = hostname,
                ddtags = tags,
                message = entry.message,
                timestamp = entry.timestamp * 1000,
                player = entry.player,
                identifiers = entry.identifiers,
                source = entry.source,
                extra = entry.extra,
            }

            if encodable(item) then
                items[#items + 1] = item
            else
                skipped = skipped + 1
            end
        end

        reportSkipped(skipped)
        if #items == 0 then return end

        PerformHttpRequest(('https://http-intake.logs.%s/api/v2/logs'):format(site), onResponse('Datadog'), 'POST', json.encode(items), {
            ['Content-Type'] = 'application/json',
            ['DD-API-KEY'] = key,
        })
    end

    --------------------------------------------------------------------------
    -- Fivemanage
    --------------------------------------------------------------------------
    local function sendFivemanage(entries)
        local key = GetConvar('msk:fivemanage:key', '')
        local dataset = GetConvar('msk:fivemanage:dataset', '')

        local items = {}
        local skipped = 0

        for i = 1, #entries do
            local entry = entries[i]

            local metadata = {
                hostname = hostname,
                service = serviceLabel,
                event = entry.event,
                source = entry.source,
                player = entry.player,
                identifiers = entry.identifiers,
                extra = entry.extra,
            }

            if entry.tags then
                for tagKey, value in pairs(entry.tags) do
                    if metadata[tagKey] == nil then
                        metadata[tagKey] = value
                    end
                end
            end

            local item = {
                level = 'info',
                message = entry.message,
                resource = entry.resource,
                metadata = metadata,
            }

            if encodable(item) then
                items[#items + 1] = item
            else
                skipped = skipped + 1
            end
        end

        reportSkipped(skipped)
        if #items == 0 then return end

        local headers = {
            ['Content-Type'] = 'application/json',
            ['Authorization'] = key,
        }

        if dataset ~= '' then
            headers['X-Fivemanage-Dataset'] = dataset
        end

        PerformHttpRequest('https://api.fivemanage.com/api/logs/batch', onResponse('Fivemanage'), 'POST', json.encode(items), headers)
    end

    local SENDERS = {
        loki = sendLoki,
        datadog = sendDatadog,
        fivemanage = sendFivemanage,
    }

    local send = SENDERS[serviceName]

    local function flush()
        if size == 0 or not send then return end

        local entries = queue
        queue, size = {}, 0

        local ok, err = pcall(send, entries)
        if not ok then
            MSK.Logging('error', ('MSK.Logger: sending %s entries failed: %s'):format(#entries, err))
        end
    end

    ---Queues a log entry. `source` may be a player id, 0 or nil for the server.
    ---@param source? number
    ---@param event string short machine-readable name, e.g. 'shop:purchase'
    ---@param message string
    ---@param extra? table any additional, JSON-serialisable data
    ---@param tags? string|table key:value pairs, see the header
    ---@return boolean queued false when no log service is configured
    function Logger.Log(source, event, message, extra, tags)
        if not send then return false end

        assert(type(event) == 'string', 'Parameter "event" has to be a string on function MSK.Logger.Log')
        assert(message ~= nil, 'Parameter "message" is nil on function MSK.Logger.Log')

        local playerId = tonumber(source)
        local entry = {
            timestamp = os.time(),
            resource = GetInvokingResource() or 'msk_core',
            event = event,
            message = stripColors(message),
            extra = type(extra) == 'table' and extra or nil,
            tags = parseTags(tags),
        }

        if playerId and playerId > 0 then
            local info = getPlayerInfo(playerId)

            entry.source = playerId
            entry.player = info.name
            entry.identifier = info.license
            entry.identifiers = info.identifiers
        end

        size = size + 1
        queue[size] = entry

        if size >= FLUSH_SIZE then
            flush()
        end

        return true
    end

    ---True when a log service is configured and entries are being sent.
    ---@return boolean
    function Logger.IsEnabled()
        return send ~= nil
    end

    if serviceName ~= '' and not send then
        MSK.Logging('warn', ('MSK.Logger: unknown service "%s" in msk:logger, supported are: loki, datadog, fivemanage'):format(serviceName))
    elseif serviceName == 'loki' and GetConvar('msk:loki:endpoint', '') == '' then
        MSK.Logging('warn', 'MSK.Logger: msk:logger is "loki", but msk:loki:endpoint is not set')
        send = nil
    elseif serviceName == 'datadog' and GetConvar('msk:datadog:key', '') == '' then
        MSK.Logging('warn', 'MSK.Logger: msk:logger is "datadog", but msk:datadog:key is not set')
        send = nil
    elseif serviceName == 'fivemanage' and GetConvar('msk:fivemanage:key', '') == '' then
        MSK.Logging('warn', 'MSK.Logger: msk:logger is "fivemanage", but msk:fivemanage:key is not set')
        send = nil
    end

    if send then
        CreateThread(function()
            while true do
                Wait(FLUSH_INTERVAL)
                flush()
            end
        end)

        AddEventHandler('onResourceStop', function(resource)
            if resource == 'msk_core' then flush() end
        end)
    end

    exports('LoggerLog', Logger.Log)
    exports('LoggerEnabled', Logger.IsEnabled)

    MSK.Logger = Logger
else
    function Logger.Log(source, event, message, extra, tags) return exports.msk_core:LoggerLog(source, event, message, extra, tags) end
    function Logger.IsEnabled() return exports.msk_core:LoggerEnabled() end
end

return Logger
