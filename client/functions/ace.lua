MSK.IsAceAllowed = function(command)
    return MSK.Trigger('msk_core:isAceAllowed', ('command.%s'):format(command))
end
exports('IsAceAllowed', MSK.IsAceAllowed)

MSK.IsPrincipalAceAllowed = function(restricted, ace)
    return MSK.Trigger('msk_core:isPrincipalAceAllowed', restricted, ace)
end
exports('IsPrincipalAceAllowed', MSK.IsPrincipalAceAllowed)