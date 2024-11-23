if MSK.Bridge.Framework.Type ~= 'OXCore' then return end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    local playerData = Ox.GetPlayer()

    if playerData then
        MSK.Bridge.isPlayerLoaded = true
        MSK.Bridge.PlayerData = playerData
    end
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setPlayerData, function(PlayerData)
    local invoke = GetInvokingResource()
    if not invoke or invoke ~= 'msk_core' then return end

    MSK.Bridge.PlayerData = Ox.GetPlayer()
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLoaded, function(playerId, isNew)
    MSK.Bridge.isPlayerLoaded = true
    MSK.Bridge.PlayerData = Ox.GetPlayer()
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.playerLogout, function(playerId)
    MSK.Bridge.isPlayerLoaded = false
    MSK.Bridge.PlayerData = {}
end)

RegisterNetEvent(MSK.Bridge.Framework.Events.setJob, function(groupName, grade)
    if not MSK.Bridge.PlayerData.job then
        MSK.Bridge.PlayerData.job = {}
    end

    MSK.Bridge.PlayerData.job[groupName] = grade
end)

MSK.Bridge.SetPlayerData = function(key, value)
    MSK.Bridge.PlayerData[key] = value
end