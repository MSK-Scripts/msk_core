local checkParams = function(str)
    return MSK.String.StartsWith(str, 'player.') or MSK.String.StartsWith(str, 'group.') or MSK.String.StartsWith(str, 'identifier.')
end

MSK.IsAceAllowed = function(playerId, command)
    if not MSK.String.StartsWith(command, 'command.') then
        command = ('command.%s'):format(command)
    end

    return IsPlayerAceAllowed(playerId, command)
end
exports('IsAceAllowed', MSK.IsAceAllowed)

MSK.IsPrincipalAceAllowed = function(principal, ace)
    if not checkParams(principal) then
        if type(principal) == 'string' then
            local result = MSK.String.Split(principal, ':')

            if result[2] then
                principal = 'identifier.' .. principal
            else
                principal = 'group.' .. principal
            end
        elseif tonumber(principal) then
            principal = 'player.' .. tostring(principal)
        end
    end

    return IsPrincipalAceAllowed(principal, ace)
end
exports('IsPrincipalAceAllowed', MSK.IsPrincipalAceAllowed)

local allowAce = function(allow)
    return allow == false and 'deny' or 'allow'
end

MSK.AddAce = function(principal, ace, allow)
    if not checkParams(principal) then
        if type(principal) == 'string' then
            local result = MSK.String.Split(principal, ':')

            if result[2] then
                principal = 'identifier.' .. principal
            else
                principal = 'group.' .. principal
            end
        elseif tonumber(principal) then
            principal = 'player.' .. tostring(principal)
        end
    end

    if not MSK.String.StartsWith(ace, 'command.') then
        ace = ('command.%s'):format(ace)
    end
    
    logging('debug', 'MSK.AddAce', principal, ace, allowAce(allow))

    ExecuteCommand(('add_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end
exports('AddAce', MSK.AddAce)

MSK.RemoveAce = function(principal, ace, allow)
    if not checkParams(principal) then
        if type(principal) == 'string' then
            local result = MSK.String.Split(principal, ':')

            if result[2] then
                principal = 'identifier.' .. principal
            else
                principal = 'group.' .. principal
            end
        elseif tonumber(principal) then
            principal = 'player.' .. tostring(principal)
        end
    end

    if not MSK.String.StartsWith(ace, 'command.') then
        ace = ('command.%s'):format(ace)
    end

    logging('debug', 'MSK.RemoveAce', principal, ace, allowAce(allow))

    ExecuteCommand(('remove_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end
exports('RemoveAce', MSK.RemoveAce)

MSK.AddPrincipal = function(child, parent)
    if type(principal) == 'number' then
        principal = 'player.' .. principal
    end

    if not MSK.String.StartsWith(parent, 'group.') then
        parent = ('group.%s'):format(parent)
    end

    logging('debug', 'MSK.AddPrincipal', child, parent)

    ExecuteCommand(('add_principal %s %s'):format(child, parent))
end
exports('AddPrincipal', MSK.AddPrincipal)

MSK.RemovePrincipal = function(child, parent)
    if type(principal) == 'number' then
        principal = 'player.' .. principal
    end

    if not MSK.String.StartsWith(parent, 'group.') then
        parent = ('group.%s'):format(parent)
    end

    logging('debug', 'MSK.RemovePrincipal', child, parent)

    ExecuteCommand(('remove_principal %s %s'):format(child, parent))
end
exports('RemovePrincipal', MSK.RemovePrincipal)