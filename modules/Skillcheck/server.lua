--------------------------------------------------------------------------------
-- MSK.Skillcheck (server)
--
-- Runs a skillcheck on a client and waits for the result.
--
--   if MSK.Skillcheck.Start(source, 'hard') then ... end
--
-- The result is reported by the client. Fine for gameplay, but do not let it
-- alone decide over money or items without a server-side plausibility check.
--------------------------------------------------------------------------------
local Skillcheck = {}

---@param playerId number
---@param difficulty? string|table|table[]
---@param inputs? string[]
---@return boolean passed
function Skillcheck.Start(playerId, difficulty, inputs)
    assert(tonumber(playerId), 'Parameter "playerId" has to be a number on function MSK.Skillcheck.Start')
    -- TriggerAwait: several rounds easily take longer than 5 seconds.
    return MSK.TriggerAwait('msk_core:skillcheck', playerId, nil, difficulty, inputs) == true
end

return setmetatable(Skillcheck, {
    __call = function(_, ...) return Skillcheck.Start(...) end
})
