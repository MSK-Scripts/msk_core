--------------------------------------------------------------------------------
-- MSK.Alert (server)
--
-- Shows an alert dialog on a client and waits for the answer.
--
--   local answer = MSK.Alert.Show(source, { header = 'Trade', content = 'Accept?' })
--
-- Returns 'confirm', 'cancel', 'timeout' (with data.timeout) or nil. The
-- answer comes from the client, so treat it like any other client input.
--------------------------------------------------------------------------------
local Alert = {}

---@param playerId number
---@param data table
---@return 'confirm'|'cancel'|'timeout'|nil
function Alert.Show(playerId, data)
    assert(tonumber(playerId), 'Parameter "playerId" has to be a number on function MSK.Alert.Show')
    -- TriggerAwait: reading and answering takes longer than 5 seconds.
    return MSK.TriggerAwait('msk_core:alert', playerId, nil, data)
end

return setmetatable(Alert, {
    __call = function(_, playerId, data) return Alert.Show(playerId, data) end
})
