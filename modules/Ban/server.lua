local IS_CORE = GetCurrentResourceName() == 'msk_core'

-- The ban system is core-owned: the DB table, the ban cache and the
-- onResourceStart / playerConnecting handlers (the latter CancelEvent()s to kick
-- banned players) plus the /ban and /unban commands must exist EXACTLY ONCE,
-- inside msk_core. A consumer that eager-loads this module would otherwise enforce
-- bans twice and register the commands a second time. Consumers reach the
-- functions through the export proxy (exports.msk_core:BanPlayer, …).
if IS_CORE then

-- Insert you Discord Webhook here
local webhookLink = "https://discord.com/api/webhooks/"

local function banLog(playerId, bannedby, targetId, targetName, banTime, reason, playerIds, banId)
    if not Config.BanSystem.discordLog then return end

    local title = "MSK Bansystem"
    local description = ('Player %s (ID: %s) was banned by %s (ID: %s) for %s until %s. BanID: %s'):format(targetName, targetId, bannedby, playerId or 0, reason, banTime, banId)
    local fields = {
        {name = "Some IDs", value = playerIds},
    }
    local footer = {
        text = "© MSK Scripts",
        link = "https://i.imgur.com/PizJGsh.png"
    }
    local time = "%d/%m/%Y %H:%M:%S"

    MSK.AddWebhook(webhookLink, Config.BanSystem.botColor, Config.BanSystem.botName, Config.BanSystem.botAvatar, title, description, fields, footer, time)
end

local function unbanLog(playerId, unbannedby, banId)
    if not Config.BanSystem.discordLog then return end

    local title = "MSK Bansystem"
    local description = ('BanID %s was unbanned by Player %s (ID: %s)'):format(banId, unbannedby, playerId or 0)
    local footer = {
        text = "© MSK Scripts",
        link = "https://i.imgur.com/PizJGsh.png"
    }
    local time = "%d/%m/%Y %H:%M:%S"

    MSK.AddWebhook(webhookLink, Config.BanSystem.botColor, Config.BanSystem.botName, Config.BanSystem.botAvatar, title, description, false, footer, time)
end

local bannedPlayers = {}

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not Config.BanSystem.enable then return end
    MySQL.query.await("CREATE TABLE IF NOT EXISTS msk_bansystem (`id` int(10) NOT NULL AUTO_INCREMENT, `ids` longtext DEFAULT NULL, `time` text NULL, `reason` text NOT NULL, `bannedby` varchar(80) NOT NULL, PRIMARY KEY (`id`));")
    MySQL.query.await('ALTER TABLE msk_bansystem ADD COLUMN IF NOT EXISTS `tokens` longtext DEFAULT NULL;')

    local data = MySQL.query.await("SELECT * FROM msk_bansystem")
    if not data then return end

    for _, v in pairs(data) do
        bannedPlayers[#bannedPlayers + 1] = {id = v.id, ids = json.decode(v.ids), reason = v.reason, time = v.time, from = v.bannedby, tokens = json.decode(v.tokens)}
    end
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local playerId = source
    if not Config.BanSystem.enable then return end
    local isBanned, expired = MSK.IsPlayerBanned(playerId)

    if isBanned and not expired then
        setKickReason(('Banned by %s until %s for %s. BanID: %s'):format(isBanned.from, isBanned.time, isBanned.reason, isBanned.id))
        CancelEvent()
    elseif isBanned and expired then
        MSK.UnbanPlayer(nil, isBanned.id)
    end
end)

local function formatTime(time)
    local banTime = 0

    if time:find('P') then
        banTime = os.time() + (60 * 60 * 24 * 7 * 52 * 100)
    elseif time:find('M') then
        banTime = os.time() + (60 * MSK.String.Split(time, 'M')[1])
    elseif time:find('H') then
        banTime = os.time() + (60 * 60 * MSK.String.Split(time, 'H')[1])
    elseif time:find('D') then
        banTime = os.time() + (60 * 60 * 24 * MSK.String.Split(time, 'D')[1])
    elseif time:find('W') then
        banTime = os.time() + (60 * 60 * 24 * 7 * MSK.String.Split(time, 'W')[1])
    end

    return banTime, os.date('%d-%m-%Y %H:%M', banTime)
end

local function IsTokenMatching(token, tokens)
    if not tokens then return false end

    for i = 0, #tokens do
        if tokens[i] == token then
            return true
        end
    end
    return false
end

local function IsTokenBanned(playerId, banTokens)
    local num = GetNumPlayerTokens(playerId)

    for i = 0, num - 1 do
        local playerToken = GetPlayerToken(playerId, i)

        if IsTokenMatching(playerToken, banTokens) then
            return true
        end
    end
    return false
end

local function IsIdBanned(player, playerIds)
    for name, id in pairs(playerIds) do
        if player[name] and player[name] == id then
            return true
        end
    end
    return false
end

function MSK.IsPlayerBanned(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local player = {}

    player.name = GetPlayerName(playerId)
    for _, v in pairs(identifiers) do
        player[MSK.String.Split(v, ':')[1]] = v
    end

    for i = 1, #bannedPlayers do
        local timeUntil = bannedPlayers[i].time
        local isTokenBanned = IsTokenBanned(playerId, bannedPlayers[i].tokens)
        local isIdBanned = IsIdBanned(player, bannedPlayers[i].ids)

        if isTokenBanned or isIdBanned then
            local day, month, year, hour, minute = timeUntil:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
            local time = os.time({day = day, month = month, year = year, hour = hour, min = minute})

            if os.time() > time then
                return bannedPlayers[i], true
            end
            return bannedPlayers[i], false
        end
    end

    return false, true
end
exports('IsPlayerBanned', MSK.IsPlayerBanned)

function MSK.BanPlayer(playerId, targetId, time, reason)
    local targetName = GetPlayerName(targetId)

    if not targetName then
        if playerId then MSK.Notification(playerId, 'MSK Bansystem', ('Player with ID ~y~%s~s~ not found!'):format(targetId)) end
        return logging('debug', ('Player with ^2ID %s^0 not found!'):format(targetId))
    end

    local identifiers = GetPlayerIdentifiers(targetId)
    local timestamp, banTime = formatTime(time)
    local player, tokens = {}, {}

    player.name = targetName
    for _, v in pairs(identifiers) do
        player[MSK.String.Split(v, ':')[1]] = v
    end

    local num = GetNumPlayerTokens(targetId)
    for i = 0, num - 1 do
        tokens[#tokens + 1] = GetPlayerToken(targetId, i)
    end

    local bannedby = 'System'
    if playerId then bannedby = GetPlayerName(playerId) end

    MySQL.query('INSERT INTO msk_bansystem (ids, time, reason, bannedby, tokens) VALUES (@ids, @time, @reason, @bannedby, @tokens)', {
        ['@ids'] = json.encode(player),
        ['@time'] = banTime,
        ['@reason'] = reason,
        ['@bannedby'] = bannedby,
        ['@tokens'] = json.encode(tokens)
    }, function(response)
        if response then
            local banId = tonumber(response.insertId)

            logging('debug', ('Player with ID ^3%s^0 was banned until ^3%s^0 for Reason ^3%s^0. BanID: ^3%s^0'):format(targetId, banTime, reason, banId))
            if playerId then
                MSK.Notification(playerId, 'MSK Bansystem', ('Player with ID ~y~%s~s~ was banned until ~y~%s~s~ for Reason ~y~%s~s~. BanID: ~y~%s~s~'):format(targetId, banTime, reason, banId))
            end

            bannedPlayers[#bannedPlayers + 1] = {id = banId, ids = player, reason = reason, time = banTime, from = bannedby, tokens = tokens}
            banLog(playerId, bannedby, targetId, targetName, banTime, reason, json.encode(player), banId)
            DropPlayer(targetId, ('Banned by %s for %s until %s. BanID: %s'):format(bannedby, reason, banTime, banId))
        end
    end)
end
exports('BanPlayer', MSK.BanPlayer)

function MSK.UnbanPlayer(playerId, banId)
    banId = tonumber(banId)

    MySQL.query('DELETE FROM msk_bansystem WHERE id = @id', {
        ['@id'] = banId
    }, function(response)
        if response.affectedRows > 0 then
            logging('debug', ('Player with BanID ^3%s^0 was unbanned.'):format(banId))
            if playerId then MSK.Notification(playerId, 'MSK Bansystem', ('Player with BanID ~y~%s~s~ was unbanned.'):format(banId)) end

            for i = 1, #bannedPlayers do
                if bannedPlayers[i].id == banId then
                    bannedPlayers[i] = nil
                    break
                end
            end

            local unbannedby = 'System'
            if playerId then unbannedby = GetPlayerName(playerId) end
            unbanLog(playerId, unbannedby, banId)
        else
            logging('debug', ('BanId ^3%s^0 not found'):format(banId))
            if playerId then MSK.Notification(playerId, 'MSK Bansystem', ('BanId ~y~%s~s~ not found'):format(banId)) end
        end
    end)
end
exports('UnbanPlayer', MSK.UnbanPlayer)

if Config.BanSystem.enable and Config.BanSystem.commands.enable then
    while not MSK.RegisterCommand do
        Wait(10)
    end

    MSK.RegisterCommand(Config.BanSystem.commands.ban, function(source, args, raw)
        local targetId, time, reason = args.playerId, args.time, args.reason
        if not reason then reason = 'Unknown reason' end
        MSK.BanPlayer(source, targetId, time, reason)
    end, {
        allowConsole = true,
        restricted = Config.BanSystem.commands.groups,
        help = 'Ban a Player',
        params = {
            {name = "playerId", type = 'playerId', help = "Target players server id"},
            {name = "time", type = 'string', help = "1M = 1 Minute / 1H = 1 Hour / 1D = 1 Day / 1W = 1 Week / P = Permanent"},
            {name = "reason", type = 'string', help = "Ban Reason", optional = true},
        }
    })

    MSK.RegisterCommand(Config.BanSystem.commands.unban, function(source, args, raw)
        MSK.UnbanPlayer(source, args.banId)
    end, {
        allowConsole = true,
        restricted = Config.BanSystem.commands.groups,
        help = 'Unban a Player',
        params = {
            {name = 'banId', type = 'number', help = 'Banned players BanId'}
        }
    })
end

else
    -- Consumer view: route to the single ban system inside msk_core.
    function MSK.IsPlayerBanned(...) return exports.msk_core:IsPlayerBanned(...) end
    function MSK.BanPlayer(...) return exports.msk_core:BanPlayer(...) end
    function MSK.UnbanPlayer(...) return exports.msk_core:UnbanPlayer(...) end
end

return true
