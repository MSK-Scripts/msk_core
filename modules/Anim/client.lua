--------------------------------------------------------------------------------
-- MSK.Anim (client)
--
-- Plays animations without the load / play / release boilerplate.
--
--   MSK.Anim.Play(nil, 'mp_common', 'givetake1_a', { duration = 2000, flag = 49 })
--   MSK.Anim.Play(ped, 'amb@world_human_clipboard@male@idle_a', 'idle_c', { wait = true })
--
-- `ped` nil means the player's own ped.
--------------------------------------------------------------------------------
local Anim = {}

local function resolvePed(ped)
    return ped or MSK.Player.ped
end

---Plays an animation. Options (all optional):
---  blendIn 8.0, blendOut -8.0, duration -1, flag 0, rate 0.0,
---  lockX/lockY/lockZ false, wait false (block until the animation ends).
---@param ped? number
---@param dict string
---@param clip string
---@param options? { blendIn?: number, blendOut?: number, duration?: number, flag?: number, rate?: number, lockX?: boolean, lockY?: boolean, lockZ?: boolean, wait?: boolean }
function Anim.Play(ped, dict, clip, options)
    assert(type(dict) == 'string', 'Parameter "dict" has to be a string on function MSK.Anim.Play')
    assert(type(clip) == 'string', 'Parameter "clip" has to be a string on function MSK.Anim.Play')

    ped = resolvePed(ped)
    options = options or {}

    MSK.Request.AnimDict(dict)

    TaskPlayAnim(ped, dict, clip,
        options.blendIn or 8.0,
        options.blendOut or -8.0,
        options.duration or -1,
        options.flag or 0,
        options.rate or 0.0,
        options.lockX == true, options.lockY == true, options.lockZ == true)

    -- The task keeps its own reference, the dictionary can be released now.
    RemoveAnimDict(dict)

    if options.wait then
        local duration = tonumber(options.duration) or -1
        local looping = (math.floor(tonumber(options.flag) or 0) & 1) == 1

        -- A looping animation without a duration never ends, so waiting for it
        -- used to block the calling thread for good.
        if looping and duration < 0 then
            MSK.Logging('warn', ('MSK.Anim.Play: "%s" / "%s" loops without a duration, wait is ignored.'):format(dict, clip))
            return
        end

        -- TaskPlayAnim needs a moment before the ped reports the animation.
        local deadline = GetGameTimer() + 1000
        while not IsEntityPlayingAnim(ped, dict, clip, 3) and GetGameTimer() < deadline do
            Wait(0)
        end

        local stopAt = duration > 0 and (GetGameTimer() + duration + 500) or nil

        while IsEntityPlayingAnim(ped, dict, clip, 3) do
            if stopAt and GetGameTimer() > stopAt then break end
            Wait(0)
        end
    end
end

---@param ped? number
---@param dict string
---@param clip string
---@param blendOut? number default 1.0
function Anim.Stop(ped, dict, clip, blendOut)
    StopAnimTask(resolvePed(ped), dict, clip, blendOut or 1.0)
end

---@param ped? number
---@param dict string
---@param clip string
---@return boolean
function Anim.IsPlaying(ped, dict, clip)
    return IsEntityPlayingAnim(resolvePed(ped), dict, clip, 3)
end

---Starts a scenario (e.g. 'WORLD_HUMAN_SMOKING') in place.
---@param ped? number
---@param scenario string
---@param playEnter? boolean default true
function Anim.Scenario(ped, scenario, playEnter)
    assert(type(scenario) == 'string', 'Parameter "scenario" has to be a string on function MSK.Anim.Scenario')
    TaskStartScenarioInPlace(resolvePed(ped), scenario, 0, playEnter ~= false)
end

---Ends whatever the ped is doing, animations and scenarios included.
---@param ped? number
---@param immediately? boolean
function Anim.Clear(ped, immediately)
    if immediately then
        ClearPedTasksImmediately(resolvePed(ped))
    else
        ClearPedTasks(resolvePed(ped))
    end
end

return setmetatable(Anim, {
    __call = function(_, ...) return Anim.Play(...) end
})
