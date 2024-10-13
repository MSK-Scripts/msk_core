MSK.IsAceAllowed = function(playerId, command)
    return IsPlayerAceAllowed(playerId, ('command.%s'):format(command))
end
exports('IsAceAllowed', MSK.IsAceAllowed)

local allowAce = function(allow)
    return allow == false and 'deny' or 'allow'
end

MSK.AddAce = function(principal, ace, allow)
    if type(principal) == 'string' then
        principal = 'group.' .. principal
    elseif type(principal) == 'number' then
        principal = 'player.' .. principal
    end

    ExecuteCommand(('add_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end
exports('AddAce', MSK.AddAce)

MSK.RemoveAce = function(principal, ace, allow)
    if type(principal) == 'string' then
        principal = 'group.' .. principal
    elseif type(principal) == 'number' then
        principal = 'player.' .. principal
    end

    ExecuteCommand(('remove_ace %s %s %s'):format(principal, ace, allowAce(allow)))
end
exports('RemoveAce', MSK.RemoveAce)

MSK.AddPrincipal = function(child, parent)
    if type(principal) == 'number' then
        principal = 'player.' .. principal
    end

    ExecuteCommand(('add_principal %s %s'):format(child, parent))
end
exports('AddPrincipal', MSK.AddPrincipal)

MSK.RemovePrincipal = function(child, parent)
    if type(principal) == 'number' then
        principal = 'player.' .. principal
    end

    ExecuteCommand(('remove_principal %s %s'):format(child, parent))
end
exports('RemovePrincipal', MSK.RemovePrincipal)