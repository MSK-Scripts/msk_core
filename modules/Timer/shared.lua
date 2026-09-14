--------------------------------------------------------------------------------
-- MSK.Timer
--
-- A countdown that can be paused, resumed, stopped and restarted.
--
--   local timer = MSK.Timer.New(30000, function(self)
--       print('time is up')
--   end)
--
--   timer:Pause()
--   timer:GetTimeLeft('s')   -- 21.37
--   timer:Resume()
--
-- There is no polling thread. Starting or resuming arms one thread that sleeps
-- for the remaining time; pausing, stopping or restarting bumps a generation
-- counter, and a thread that wakes up to a different generation just returns.
--------------------------------------------------------------------------------
local Timer = {}
Timer.__index = Timer

local UNITS = { ms = 1, s = 1000, m = 60000, h = 3600000 }

local function arm(self)
    self.generation = self.generation + 1
    local generation = self.generation

    self.startedAt = GetGameTimer()
    self.state = 'running'

    local wait = self.remaining

    CreateThread(function()
        Wait(wait)

        if self.generation ~= generation or self.state ~= 'running' then return end

        self.remaining = 0
        self.state = 'finished'

        if self.onEnd then
            local ok, err = pcall(self.onEnd, self)
            if not ok then
                print(('[^1ERROR^0] MSK.Timer: onEnd failed: %s'):format(err))
            end
        end
    end)
end

local function elapsedSinceStart(self)
    return GetGameTimer() - self.startedAt
end

---Creates a timer over `duration` milliseconds. It starts right away unless
---`autoStart` is false.
---@param duration number
---@param onEnd? fun(timer: table)
---@param autoStart? boolean
function Timer.New(duration, onEnd, autoStart)
    assert(type(duration) == 'number' and duration >= 0, 'Parameter "duration" has to be a number >= 0 on function MSK.Timer.New')
    assert(onEnd == nil or type(onEnd) == 'function', 'Parameter "onEnd" has to be a function on function MSK.Timer.New')

    local self = setmetatable({
        duration = duration,
        remaining = duration,
        onEnd = onEnd,
        state = 'idle',
        generation = 0,
        startedAt = 0,
    }, Timer)

    if autoStart ~= false then
        self:Start()
    end

    return self
end

---Starts the timer from its full duration. Does nothing while it is running.
---@return boolean started
function Timer:Start()
    if self.state == 'running' then return false end

    self.remaining = self.duration
    arm(self)
    return true
end

---@return boolean paused
function Timer:Pause()
    if self.state ~= 'running' then return false end

    self.remaining = math.max(0, self.remaining - elapsedSinceStart(self))
    self.generation = self.generation + 1
    self.state = 'paused'
    return true
end

---@return boolean resumed
function Timer:Resume()
    if self.state ~= 'paused' then return false end

    arm(self)
    return true
end

---Stops the timer. With `runOnEnd` the end callback runs as if time was up.
---@param runOnEnd? boolean
---@return boolean stopped
function Timer:Stop(runOnEnd)
    if self.state ~= 'running' and self.state ~= 'paused' then return false end

    if self.state == 'running' then
        self.remaining = math.max(0, self.remaining - elapsedSinceStart(self))
    end

    self.generation = self.generation + 1

    if runOnEnd then
        self.remaining = 0
        self.state = 'finished'

        if self.onEnd then
            local ok, err = pcall(self.onEnd, self)
            if not ok then
                print(('[^1ERROR^0] MSK.Timer: onEnd failed: %s'):format(err))
            end
        end
    else
        self.state = 'stopped'
    end

    return true
end

---Starts again from the beginning, optionally with a new duration.
---@param duration? number
function Timer:Restart(duration)
    if duration ~= nil then
        assert(type(duration) == 'number' and duration >= 0, 'Parameter "duration" has to be a number >= 0 on function Timer:Restart')
        self.duration = duration
    end

    self.remaining = self.duration
    arm(self)
end

---Remaining time in `unit`: 'ms' (default), 's', 'm' or 'h'. Everything but
---milliseconds is rounded to two decimals.
---@param unit? 'ms'|'s'|'m'|'h'
---@return number
function Timer:GetTimeLeft(unit)
    local divisor = UNITS[unit or 'ms']
    assert(divisor, ('Unknown unit "%s" on function Timer:GetTimeLeft'):format(tostring(unit)))

    local left = self.remaining
    if self.state == 'running' then
        left = math.max(0, left - elapsedSinceStart(self))
    end

    if divisor == 1 then
        return math.floor(left)
    end

    return math.floor(left / divisor * 100 + 0.5) / 100
end

---@return boolean
function Timer:IsRunning() return self.state == 'running' end

---@return boolean
function Timer:IsPaused() return self.state == 'paused' end

---@return boolean
function Timer:IsFinished() return self.state == 'finished' end

---@param onEnd? fun(timer: table)
function Timer:SetOnEnd(onEnd)
    assert(onEnd == nil or type(onEnd) == 'function', 'Parameter "onEnd" has to be a function on function Timer:SetOnEnd')
    self.onEnd = onEnd
end

return { New = Timer.New }
