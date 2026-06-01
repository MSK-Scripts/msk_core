function MSK.IsAceAllowed(command)
    return MSK.Trigger('msk_core:isAceAllowed', ('command.%s'):format(command))
end
exports('IsAceAllowed', MSK.IsAceAllowed)

function MSK.IsPrincipalAceAllowed(restricted, ace)
    return MSK.Trigger('msk_core:isPrincipalAceAllowed', restricted, ace)
end
exports('IsPrincipalAceAllowed', MSK.IsPrincipalAceAllowed)

return true
