--------------------------------------------------------------------------------
-- MSK.Skillcheck (client)
--
-- A timing check: a marker runs around a circle and the player has to press
-- the shown key while it is inside the highlighted area.
--
--   if MSK.Skillcheck.Start('medium') then ... end
--   MSK.Skillcheck.Start({ 'easy', 'easy', 'hard' }, { 'w', 'a', 's', 'd' })
--   MSK.Skillcheck.Start({ areaSize = 30, speedMultiplier = 2 })
--
-- difficulty: 'easy', 'medium', 'hard', a table { areaSize (degrees),
-- speedMultiplier }, or a list of those for several rounds in a row. Every
-- round has to be passed. inputs: keys to pick from per round, default { 'e' }.
--
-- Returns true when every round was passed, false otherwise. The result comes
-- from the client, so do not use it as the only check for anything valuable.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Skillcheck = {}

if IS_CORE then
    local PRESETS = {
        easy = { areaSize = 50, speedMultiplier = 1.0 },
        medium = { areaSize = 40, speedMultiplier = 1.5 },
        hard = { areaSize = 25, speedMultiplier = 1.75 },
    }

    local active = false
    local pendingPromise = nil

    local function settle(value)
        local waiting = pendingPromise
        pendingPromise = nil

        if waiting then
            waiting:resolve(value)
        end
    end

    local function clamp(value, min, max)
        return math.max(min, math.min(max, value))
    end

    local function toRound(entry)
        if type(entry) == 'string' then
            local preset = PRESETS[entry]
            assert(preset, ('Unknown skillcheck difficulty "%s", use easy, medium or hard'):format(entry))
            entry = preset
        end

        assert(type(entry) == 'table', 'A skillcheck difficulty has to be a string or a table')

        return {
            areaSize = clamp(tonumber(entry.areaSize) or 40, 5, 180),
            speed = clamp(tonumber(entry.speedMultiplier) or 1.0, 0.1, 10.0),
        }
    end

    ---@param difficulty? string|table|table[]
    ---@param inputs? string[]
    ---@return boolean passed
    function Skillcheck.Start(difficulty, inputs)
        if active then return false end

        local rounds = {}

        if type(difficulty) == 'table' and difficulty[1] ~= nil then
            for i = 1, #difficulty do
                rounds[i] = toRound(difficulty[i])
            end
        else
            rounds[1] = toRound(difficulty or 'easy')
        end

        if type(inputs) ~= 'table' or #inputs == 0 then
            inputs = { 'e' }
        end

        active = true
        SetNuiFocus(true, false)

        local passed = true

        for i = 1, #rounds do
            if not active then
                passed = false
                break
            end

            local p = promise.new()
            pendingPromise = p

            SendNUIMessage({
                action = 'startSkillcheck',
                areaSize = rounds[i].areaSize,
                speed = rounds[i].speed,
                key = tostring(inputs[math.random(1, #inputs)]):lower(),
                round = i,
                rounds = #rounds,
            })

            if not Citizen.Await(p) then
                passed = false
                break
            end

            if i < #rounds then Wait(300) end
        end

        active = false
        pendingPromise = nil
        SetNuiFocus(false, false)

        return passed
    end

    ---Ends a running skillcheck as failed.
    function Skillcheck.Cancel()
        if not active then return end

        active = false
        SendNUIMessage({ action = 'cancelSkillcheck' })
        settle(false)
    end

    ---@return boolean
    function Skillcheck.Active()
        return active
    end

    RegisterNUICallback('skillcheckResult', function(data, cb)
        cb('ok')
        settle(data and data.success == true)
    end)

    MSK.Register('msk_core:skillcheck', function(source, difficulty, inputs)
        return Skillcheck.Start(difficulty, inputs)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= 'msk_core' then return end
        Skillcheck.Cancel()
    end)

    exports('Skillcheck', Skillcheck.Start)
    exports('CancelSkillcheck', Skillcheck.Cancel)
    exports('SkillcheckActive', Skillcheck.Active)

    MSK.Skillcheck = Skillcheck
else
    function Skillcheck.Start(difficulty, inputs) return exports.msk_core:Skillcheck(difficulty, inputs) end
    function Skillcheck.Cancel() return exports.msk_core:CancelSkillcheck() end
    function Skillcheck.Active() return exports.msk_core:SkillcheckActive() end
end

return setmetatable(Skillcheck, {
    __call = function(_, ...) return Skillcheck.Start(...) end
})
