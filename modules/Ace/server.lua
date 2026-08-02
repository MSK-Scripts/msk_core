local CORE = 'msk_core'
local IS_CORE = GetCurrentResourceName() == CORE

local function checkParams(str)
    return MSK.String.StartsWith(str, 'player.') or MSK.String.StartsWith(str, 'group.') or MSK.String.StartsWith(str, 'identifier.')
end

local function normalizePrincipal(principal)
    if not checkParams(principal) then
        if type(principal) == 'string' then
            local result = MSK.String.Split(principal, ':')
            principal = result[2] and ('identifier.' .. principal) or ('group.' .. principal)
        elseif tonumber(principal) then
            principal = 'player.' .. tostring(principal)
        end
    end
    return principal
end

local function allowAce(allow)
    return allow == false and 'deny' or 'allow'
end

function MSK.IsAceAllowed(playerId, command)
    if not MSK.String.StartsWith(command, 'command.') then
        command = ('command.%s'):format(command)
    end
    return IsPlayerAceAllowed(playerId, command)
end
exports('IsAceAllowed', MSK.IsAceAllowed)

function MSK.IsPrincipalAceAllowed(principal, ace)
    return IsPrincipalAceAllowed(normalizePrincipal(principal), ace)
end
exports('IsPrincipalAceAllowed', MSK.IsPrincipalAceAllowed)

function MSK.AddAce(principal, ace, allow)
    principal = normalizePrincipal(principal)
    if not MSK.String.StartsWith(ace, 'command.') then
        ace = ('command.%s'):format(ace)
    end
    logging('debug', 'MSK.AddAce', principal, ace, allowAce(allow))
    ExecuteCommand(('add_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end
exports('AddAce', MSK.AddAce)

function MSK.RemoveAce(principal, ace, allow)
    principal = normalizePrincipal(principal)
    if not MSK.String.StartsWith(ace, 'command.') then
        ace = ('command.%s'):format(ace)
    end
    logging('debug', 'MSK.RemoveAce', principal, ace, allowAce(allow))
    ExecuteCommand(('remove_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end
exports('RemoveAce', MSK.RemoveAce)

----------------------------------------------------------------
-- Raw aces
--
-- FiveM checks `add_ace` against the resource that RUNS the command, and no
-- resource holds `command.add_ace` by default. Consumers cannot fix this for
-- themselves: import.lua compiles these modules INTO the consumer, so a plain
-- ExecuteCommand here would run as `resource.<consumer>` and be denied.
--
-- The two functions below therefore bounce through msk_core's own export when
-- they are called from a consumer. Then the command runs as `resource.msk_core`
-- and a single line in the server.cfg covers every MSK script:
--
--     add_ace resource.msk_core command.add_ace allow
--
-- "Raw" means: no `command.` prefix is added, unlike MSK.AddAce. That matters
-- for permission objects that must NOT inherit from `command`, because almost
-- every server.cfg contains `add_ace group.admin command allow` and ace objects
-- are inherited by their children. An object named `command.something` would be
-- handed to everyone holding `command`.
----------------------------------------------------------------

function MSK.CanAddAce()
    return IsPrincipalAceAllowed(('resource.%s'):format(CORE), 'command.add_ace')
end
exports('CanAddAce', MSK.CanAddAce)

-- Both take principal AND ace exactly as given, no normalising. A caller that
-- needs `qbcore.admin` or `resource.foo` must be able to say so: passing it
-- through normalizePrincipal() would turn `qbcore.admin` into
-- `group.qbcore.admin`.
function MSK.AddRawAce(principal, ace, allow)
    if not IS_CORE then return exports[CORE]:AddRawAce(principal, ace, allow) end
    if not MSK.CanAddAce() then return false end

    logging('debug', 'MSK.AddRawAce', principal, ace, allowAce(allow))
    ExecuteCommand(('add_ace %s %s %s'):format(principal, ace, allowAce(allow)))
    return true
end
exports('AddRawAce', MSK.AddRawAce)

function MSK.RemoveRawAce(principal, ace, allow)
    if not IS_CORE then return exports[CORE]:RemoveRawAce(principal, ace, allow) end
    if not MSK.CanAddAce() then return false end

    logging('debug', 'MSK.RemoveRawAce', principal, ace, allowAce(allow))
    ExecuteCommand(('remove_ace %s %s %s'):format(principal, ace, allowAce(allow)))
    return true
end
exports('RemoveRawAce', MSK.RemoveRawAce)

function MSK.AddPrincipal(child, parent)
    if type(child) == 'number' then child = 'player.' .. child end
    if not MSK.String.StartsWith(parent, 'group.') then
        parent = ('group.%s'):format(parent)
    end
    logging('debug', 'MSK.AddPrincipal', child, parent)
    ExecuteCommand(('add_principal %s %s'):format(child, parent))
end
exports('AddPrincipal', MSK.AddPrincipal)

function MSK.RemovePrincipal(child, parent)
    if type(child) == 'number' then child = 'player.' .. child end
    if not MSK.String.StartsWith(parent, 'group.') then
        parent = ('group.%s'):format(parent)
    end
    logging('debug', 'MSK.RemovePrincipal', child, parent)
    ExecuteCommand(('remove_principal %s %s'):format(child, parent))
end
exports('RemovePrincipal', MSK.RemovePrincipal)

-- These callbacks back the client-side MSK.IsAceAllowed / MSK.IsPrincipalAceAllowed
-- (they resolve via MSK.Trigger). They are server-side singletons owned by
-- msk_core alone. A consumer that eager-loads this module would otherwise
-- re-register them through the export proxy onto the core, overwriting the core
-- handler with a closure that points back into the consumer resource. Only the
-- core registers them.
if IS_CORE then
    MSK.Register('msk_core:isAceAllowed', function(source, command)
        return MSK.IsAceAllowed(source, command)
    end)

    MSK.Register('msk_core:isPrincipalAceAllowed', function(source, principal, ace)
        return MSK.IsPrincipalAceAllowed(principal, ace)
    end)
end

return true
