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

MSK.Register('msk_core:isAceAllowed', function(source, command)
    return MSK.IsAceAllowed(source, command)
end)

MSK.Register('msk_core:isPrincipalAceAllowed', function(source, principal, ace)
    return MSK.IsPrincipalAceAllowed(principal, ace)
end)

return true
