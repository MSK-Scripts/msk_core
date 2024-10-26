MSK.Progress = {}

local isProgressActive, progressData = false, nil

local Controls = {
    INPUT_LOOK_LR = 1,
    INPUT_LOOK_UD = 2,
    INPUT_SPRINT = 21,
    INPUT_AIM = 25,
    INPUT_MOVE_LR = 30,
    INPUT_MOVE_UD = 31,
    INPUT_DUCK = 36,
    INPUT_VEH_MOVE_LEFT_ONLY = 63,
    INPUT_VEH_MOVE_RIGHT_ONLY = 64,
    INPUT_VEH_ACCELERATE = 71,
    INPUT_VEH_BRAKE = 72,
    INPUT_VEH_EXIT = 75,
    INPUT_VEH_MOUSE_CONTROL_OVERRIDE = 106
}

local interrupted = function(data)
    if not data.useWhileDead and IsEntityDead(MSK.Player.ped) then return true end
    if not data.useWhileRagdoll and IsPedRagdoll(MSK.Player.ped) then return true end
    if not data.useWhileCuffed and IsPedCuffed(MSK.Player.ped) then return true end
    if not data.useWhileFalling and IsPedFalling(MSK.Player.ped) then return true end
    if not data.useWhileSwimming and IsPedSwimming(MSK.Player.ped) then return true end
end

local setProgressData = function(data)
    progressData = data
    local anim = data.animation

    if anim then
        if anim.dict then
            MSK.Request.AnimDict(anim.dict)
            TaskPlayAnim(MSK.Player.ped, anim.dict, anim.anim, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1, anim.flag or 49, anim.playbackRate or 0, anim.lockX, anim.lockY, anim.lockZ)
            RemoveAnimDict(anim.dict)
        elseif anim.scenario then
            TaskStartScenarioInPlace(MSK.Player.ped, anim.scenario, 0, anim.playEnter ~= nil and anim.playEnter or true)
        end
    end

    local disable = data.disable

    while isProgressActive do
        if disable then
            if disable.mouse then
                DisableControlAction(0, Controls.INPUT_LOOK_LR, true)
                DisableControlAction(0, Controls.INPUT_LOOK_UD, true)
                DisableControlAction(0, Controls.INPUT_VEH_MOUSE_CONTROL_OVERRIDE, true)
            end

            if disable.move then
                DisableControlAction(0, Controls.INPUT_SPRINT, true)
                DisableControlAction(0, Controls.INPUT_MOVE_LR, true)
                DisableControlAction(0, Controls.INPUT_MOVE_UD, true)
                DisableControlAction(0, Controls.INPUT_DUCK, true)
            end

            if disable.sprint and not disable.move then
                DisableControlAction(0, Controls.INPUT_SPRINT, true)
            end

            if disable.vehicle then
                DisableControlAction(0, Controls.INPUT_VEH_MOVE_LEFT_ONLY, true)
                DisableControlAction(0, Controls.INPUT_VEH_MOVE_RIGHT_ONLY, true)
                DisableControlAction(0, Controls.INPUT_VEH_ACCELERATE, true)
                DisableControlAction(0, Controls.INPUT_VEH_BRAKE, true)
                DisableControlAction(0, Controls.INPUT_VEH_EXIT, true)
            end

            if disable.combat then
                DisableControlAction(0, Controls.INPUT_AIM, true)
                DisablePlayerFiring(MSK.Player.clientId, true)
            end
        end

        if interrupted(data) then
            MSK.Progress.Stop()
        end

        Wait(0)
    end

    if anim then
        if anim.dict then
            StopAnimTask(MSK.Player.ped, anim.dict, anim.clip, 1.0)
            ClearPedTasks(MSK.Player.ped)
        else
            ClearPedTasks(MSK.Player.ped)
        end
    end
end

MSK.Progress.Start = function(data, text, color)
    local duration, text, color = data, text, color
    local forceOverride = false

    if type(data) == 'table' then
        duration = data.duration
        text = data.text
        color = data.color or Config.ProgressColor or Config.progressColor
        forceOverride = data.forceOverride or forceOverride
    end

    if isProgressActive and not forceOverride then return end
    if isProgressActive then MSK.Progress.Stop() end
    isProgressActive = true

    SendNUIMessage({
        action = 'progressBarStart',
        time = duration,
        text = text or '',
        color = color or Config.ProgressColor or Config.progressColor,
    })

    if type(data) == 'table' then
        return setProgressData(data)
    end
end
MSK.Progressbar = MSK.Progress.Start -- Backwards compatibility
exports('Progressbar', MSK.Progress.Start)
RegisterNetEvent("msk_core:progressbar", MSK.Progress.Start)

setmetatable(MSK.Progress, {
    __call = function(self, ...)
        self.Start(...)
    end
})

MSK.Progress.Stop = function()
    if not isProgressActive then return end

    SendNUIMessage({
        action = 'progressBarStop',
    })

    isProgressActive = false
    progressData = nil
end
MSK.ProgressStop = MSK.Progress.Stop -- Backwards compatibility
RegisterNetEvent("msk_core:progressbarStop", MSK.Progress.Stop)

MSK.Progress.Active = function()
    return isProgressActive, isProgressActive and progressData
end
exports('ProgressActive', MSK.Progress.Active)

RegisterNUICallback('progressEnd', function()
    isProgressActive = false
    progressData = nil
end)

RegisterCommand('stopProgress', function()
    if isProgressActive and progressData and progressData.canCancel then
        MSK.Progress.Stop()
    end
end)
RegisterKeyMapping('stopProgress', 'Cancel Progressbar', 'keyboard', 'X')
TriggerEvent('chat:removeSuggestion', '/stopProgress')

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    MSK.Progress.Stop()
end)