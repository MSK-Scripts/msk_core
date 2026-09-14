--------------------------------------------------------------------------------
-- MSK.Progress (client)
--
--   local done = MSK.Progress({
--       duration = 5000,
--       text = 'Repairing',
--       position = 'bottom',            -- 'middle' or 'bottom' (bar default bottom, circle default middle)
--       canCancel = true,               -- X, rebindable in the FiveM key bindings
--       animation = { dict = 'mini@repair', clip = 'fixing_a_ped' },   -- or { scenario = 'WORLD_HUMAN_WELDING' }
--       prop = { model = 'prop_tool_wrench', bone = 57005, pos = vec3(0.1, 0.0, 0.0), rot = vec3(0.0, 0.0, 90.0) },
--       disable = { move = true, vehicle = true, combat = true },
--       useWhileDead = false,
--   })
--
--   MSK.Progress.Circle({ duration = 3000, text = 'Eating' })
--
-- Both wait until the progress ends and return true when it ran out, false
-- when it was cancelled, interrupted or could not start because another
-- progress is running (unless forceOverride = true).
--
-- Fields:
--   duration, text (or label), color, position, canCancel, forceOverride
--   animation (or anim): dict + anim (or clip), flag, blendIn, blendOut,
--                        duration, playbackRate, lockX/Y/Z  |  scenario, playEnter
--   prop: one table or a list of { model, bone (default 60309), pos, rot, rotOrder }
--   disable: mouse, move, sprint, vehicle (or car), combat
--   useWhileDead, useWhileRagdoll, useWhileCuffed, useWhileFalling, useWhileSwimming
--   (allowRagdoll, allowCuffed, allowFalling, allowSwimming work as well)
--
-- The old form MSK.Progress(duration, text, color) still works, does not wait,
-- and is deprecated.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Progress = {}

if IS_CORE then
    local Controls = {
        INPUT_LOOK_LR = 1, INPUT_LOOK_UD = 2, INPUT_SPRINT = 21, INPUT_AIM = 25,
        INPUT_MOVE_LR = 30, INPUT_MOVE_UD = 31, INPUT_DUCK = 36,
        INPUT_VEH_MOVE_LEFT_ONLY = 63, INPUT_VEH_MOVE_RIGHT_ONLY = 64,
        INPUT_VEH_ACCELERATE = 71, INPUT_VEH_BRAKE = 72, INPUT_VEH_EXIT = 75,
        INPUT_VEH_MOUSE_CONTROL_OVERRIDE = 106
    }

    -- The running progress: { id, data, cancelled, props }. Each run gets its
    -- own table, so a progress replaced through forceOverride cannot keep its
    -- wait loop alive, and a late "ended" report from the NUI cannot end the
    -- progress that replaced it.
    local current = nil
    local nextId = 0

    -- One warning per resource, not per call.
    local warnedResources = {}

    local function warnDeprecated(resource)
        resource = resource or 'msk_core'
        if warnedResources[resource] then return end
        warnedResources[resource] = true

        MSK.Logging('warn', ('Resource "%s" calls MSK.Progress(duration, text, color), which is deprecated and will be removed in a future version. Pass a table instead: MSK.Progress({ duration = ..., text = ... }). The table form waits and returns true or false.'):format(resource))
    end

    local function copy(tbl)
        local result = {}
        for key, value in pairs(tbl) do result[key] = value end
        return result
    end

    local function toVector3(value)
        if not value then return vector3(0.0, 0.0, 0.0) end
        return vector3(value.x or value[1] or 0.0, value.y or value[2] or 0.0, value.z or value[3] or 0.0)
    end

    -- Copies the caller's table and resolves the alternative field names, so
    -- the rest of the module reads one spelling and the caller's table is
    -- never changed.
    local function normalize(input)
        local data = copy(input)

        local animation = data.animation or data.anim
        if type(animation) == 'table' then
            animation = copy(animation)
            animation.anim = animation.anim or animation.clip
            data.animation = animation
        else
            data.animation = nil
        end
        data.anim = nil

        if type(data.disable) == 'table' then
            local disable = copy(data.disable)
            if disable.vehicle == nil then disable.vehicle = disable.car end
            data.disable = disable
        end

        if data.useWhileRagdoll == nil then data.useWhileRagdoll = data.allowRagdoll end
        if data.useWhileCuffed == nil then data.useWhileCuffed = data.allowCuffed end
        if data.useWhileFalling == nil then data.useWhileFalling = data.allowFalling end
        if data.useWhileSwimming == nil then data.useWhileSwimming = data.allowSwimming end

        data.duration = tonumber(data.duration) or 1000
        data.text = data.text or data.label

        return data
    end

    local function interrupted(data)
        local ped = MSK.Player.ped

        if not data.useWhileDead and IsEntityDead(ped) then return true end
        if not data.useWhileRagdoll and IsPedRagdoll(ped) then return true end
        if not data.useWhileCuffed and IsPedCuffed(ped) then return true end
        if not data.useWhileFalling and IsPedFalling(ped) then return true end
        if not data.useWhileSwimming and IsPedSwimming(ped) then return true end
    end

    local function show(state, duration, text, color, style, position)
        SendNUIMessage({
            action = style == 'circle' and 'progressCircleStart' or 'progressBarStart',
            id = state.id,
            time = duration,
            text = text or '',
            color = color or Config.ProgressColor or Config.progressColor,
            position = (position == 'middle' or position == 'bottom') and position
                or (style == 'circle' and 'middle' or 'bottom'),
        })
    end

    local function newState(data)
        nextId = nextId + 1
        return { id = nextId, data = data, cancelled = false, props = {} }
    end

    local function createProps(state, propData)
        if type(propData) ~= 'table' then return end

        local list = propData.model and { propData } or propData
        local ped = MSK.Player.ped
        local coords = GetEntityCoords(ped)

        for i = 1, #list do
            local prop = list[i]

            if type(prop) == 'table' and prop.model then
                local ok, model = pcall(MSK.Request.Model, prop.model)

                if ok and model then
                    local object = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
                    local pos, rot = toVector3(prop.pos), toVector3(prop.rot)

                    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, prop.bone or 60309),
                        pos.x, pos.y, pos.z, rot.x, rot.y, rot.z,
                        true, true, false, true, prop.rotOrder or 0, true)

                    SetModelAsNoLongerNeeded(model)
                    state.props[#state.props + 1] = object
                else
                    MSK.Logging('error', ('MSK.Progress: prop model "%s" could not be loaded'):format(tostring(prop.model)))
                end
            end
        end
    end

    local function deleteProps(state)
        for i = 1, #state.props do
            local object = state.props[i]

            if DoesEntityExist(object) then
                DetachEntity(object, true, true)
                DeleteEntity(object)
            end
        end

        state.props = {}
    end

    local function run(state)
        local data = state.data
        local ped = MSK.Player.ped
        local anim = data.animation
        local playedScenario = false

        if anim then
            if anim.dict and anim.anim then
                MSK.Request.AnimDict(anim.dict)
                TaskPlayAnim(ped, anim.dict, anim.anim, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1, anim.flag or 49, anim.playbackRate or 0,
                    anim.lockX == true, anim.lockY == true, anim.lockZ == true)
                RemoveAnimDict(anim.dict)
            elseif anim.scenario then
                -- `~= false` and not `~= nil and x or true`: the old form turned
                -- an explicit false back into true.
                TaskStartScenarioInPlace(ped, anim.scenario, 0, anim.playEnter ~= false)
                playedScenario = true
            end
        end

        createProps(state, data.prop)

        local disable = data.disable

        while current == state do
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
                Progress.Stop()
            end

            Wait(0)
        end

        if anim then
            if anim.dict and anim.anim then
                -- Only this animation. ClearPedTasks also ended whatever else
                -- the ped was doing, including tasks of other scripts.
                StopAnimTask(ped, anim.dict, anim.anim, 1.0)
            elseif playedScenario then
                ClearPedTasks(ped)
            end
        end

        deleteProps(state)

        return not state.cancelled
    end

    -- Table form: shows the progress and waits for its end.
    local function begin(input, style)
        if current and not input.forceOverride then return false end
        if current then Progress.Stop() end

        local data = normalize(input)
        local state = newState(data)
        current = state

        show(state, data.duration, data.text, data.color, style, data.position)

        return run(state)
    end

    -- Deprecated number form: shows the progress and returns right away.
    local function beginLegacy(duration, text, color, style)
        if current then return end

        local state = newState(nil)
        current = state

        show(state, duration, text, color, style, nil)
    end

    ---@param data table (the number form is deprecated)
    ---@return boolean? finished
    function Progress.Start(data, text, color)
        if type(data) ~= 'table' then
            warnDeprecated(GetInvokingResource())
            return beginLegacy(data, text, color, nil)
        end

        return begin(data, data.type == 'circle' and 'circle' or nil)
    end

    ---Same as Progress.Start, shown as a circle.
    ---@param data table (the number form is deprecated)
    ---@return boolean? finished
    function Progress.Circle(data, text, color)
        if type(data) ~= 'table' then
            warnDeprecated(GetInvokingResource())
            return beginLegacy(data, text, color, 'circle')
        end

        return begin(data, 'circle')
    end

    function Progress.Stop()
        local state = current
        if not state then return end

        state.cancelled = true
        current = nil

        SendNUIMessage({ action = 'progressBarStop' })
    end

    ---@return boolean active, table? data
    function Progress.Active()
        return current ~= nil, current and current.data
    end

    MSK.Progressbar = Progress.Start  -- Backwards compatibility
    MSK.ProgressStop = Progress.Stop  -- Backwards compatibility
    exports('Progressbar', Progress.Start)
    exports('ProgressCircle', Progress.Circle)
    exports('ProgressStop', Progress.Stop)
    exports('ProgressActive', Progress.Active)

    -- Server -> client. The server warns about the deprecated form on its own
    -- side, so these handlers do not warn again.
    RegisterNetEvent("msk_core:progressbar", function(data, text, color)
        if type(data) == 'table' then
            begin(data, data.type == 'circle' and 'circle' or nil)
        else
            beginLegacy(data, text, color, nil)
        end
    end)

    RegisterNetEvent("msk_core:progressCircle", function(data, text, color)
        if type(data) == 'table' then
            begin(data, 'circle')
        else
            beginLegacy(data, text, color, 'circle')
        end
    end)

    RegisterNetEvent("msk_core:progressbarStop", Progress.Stop)

    -- Server-side MSK.Progress with a table waits for this result.
    MSK.Register('msk_core:progress', function(source, data, style)
        if type(data) ~= 'table' then return false end
        return begin(data, style == 'circle' and 'circle' or (data.type == 'circle' and 'circle' or nil))
    end)

    RegisterNUICallback('progressEnd', function(data, cb)
        cb('ok')

        -- Only the progress the NUI is reporting about may end here.
        if current and data and tonumber(data.id) == current.id then
            current = nil
        end
    end)

    RegisterCommand('stopProgress', function()
        if current and current.data and current.data.canCancel then
            Progress.Stop()
        end
    end)
    RegisterKeyMapping('stopProgress', 'Cancel Progressbar', 'keyboard', 'X')
    TriggerEvent('chat:removeSuggestion', '/stopProgress')

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end

        -- The wait loop dies with the resource and never reaches its cleanup,
        -- so attached props would stay in the world.
        if current then deleteProps(current) end
        Progress.Stop()
    end)

    MSK.Progress = setmetatable(Progress, {
        __call = function(self, ...) return self.Start(...) end
    })
    return MSK.Progress
else
    function Progress.Start(...) return exports.msk_core:Progressbar(...) end
    function Progress.Circle(...) return exports.msk_core:ProgressCircle(...) end
    function Progress.Stop() return exports.msk_core:ProgressStop() end
    function Progress.Active() return exports.msk_core:ProgressActive() end

    return setmetatable(Progress, {
        __call = function(self, ...) return self.Start(...) end
    })
end
