--------------------------------------------------------------------------------
-- MSK.Events (server)
--
-- TriggerClientEvent serialises its arguments again for every single call. To
-- send the same event to a list of players, these helpers pack the arguments
-- once and hand the same payload to every target.
--
--   MSK.Events.TriggerClients('my_script:update', { 1, 4, 9 }, data)
--   MSK.Events.TriggerClientsInRange('my_script:boom', coords, 50.0, coords)
--------------------------------------------------------------------------------
local Events = {}

local packArgs = msgpack.pack_args

---Sends `eventName` to one player, several players or -1 for everyone, with the
---arguments serialised only once.
---@param eventName string
---@param targets number|number[]
---@param ... any
function Events.TriggerClients(eventName, targets, ...)
    assert(type(eventName) == 'string', 'Parameter "eventName" has to be a string on function MSK.Events.TriggerClients')

    local payload = packArgs(...)
    local length = #payload

    if type(targets) == 'table' then
        for i = 1, #targets do
            TriggerClientEventInternal(eventName, tostring(targets[i]), payload, length)
        end
    else
        assert(tonumber(targets), 'Parameter "targets" has to be a player id or a list of player ids on function MSK.Events.TriggerClients')
        TriggerClientEventInternal(eventName, tostring(targets), payload, length)
    end
end

---Ids of all players whose ped is within `radius` of `coords`.
---@param coords vector3
---@param radius number
---@return number[]
function Events.GetPlayersInRange(coords, radius)
    assert(coords, 'Parameter "coords" is nil on function MSK.Events.GetPlayersInRange')
    assert(type(radius) == 'number', 'Parameter "radius" has to be a number on function MSK.Events.GetPlayersInRange')

    coords = vector3(coords.x, coords.y, coords.z)

    local result, n = {}, 0
    local players = GetPlayers()

    for i = 1, #players do
        local playerId = tonumber(players[i])
        local ped = GetPlayerPed(playerId)

        if ped ~= 0 and #(GetEntityCoords(ped) - coords) <= radius then
            n = n + 1
            result[n] = playerId
        end
    end

    return result
end

---Sends `eventName` to every player within `radius` of `coords`.
---@param eventName string
---@param coords vector3
---@param radius number
---@param ... any
---@return number[] targets the players that received the event
function Events.TriggerClientsInRange(eventName, coords, radius, ...)
    local targets = Events.GetPlayersInRange(coords, radius)

    if #targets > 0 then
        Events.TriggerClients(eventName, targets, ...)
    end

    return targets
end

return Events
