--------------------------------------------------------------------------------
-- Bridge module
--
-- Makes MSK.Bridge a real table in a consumer.
--
-- Inside msk_core, MSK.Bridge is set directly by bridge/shared.lua. In a
-- consumer it used to be something else entirely: import.lua finds no module
-- and no alias called 'Bridge', so it falls through to the generic export
-- proxy and MSK.Bridge becomes a function. Every script written against
--     if MSK.Bridge and MSK.Bridge.Framework and MSK.Bridge.Framework.Type ...
-- passed the first check and then raised "attempt to index a function value".
--
-- With this module the same line works, and it reads the same values the core
-- holds.
--
-- What lives here is what stays true for the whole runtime: which framework
-- and which inventory were detected, and the event names. Player data changes
-- constantly and is not cached here, MSK.GetPlayerData() answers that.
--------------------------------------------------------------------------------
if GetCurrentResourceName() == 'msk_core' then
    -- Inside the core the real table already exists. Returning it keeps
    -- MSK.LoadModule('Bridge') pointing at the same object rather than a copy.
    return MSK.Bridge
end

local info = exports.msk_core:GetBridgeInfo()

local Bridge = {
    Framework = {
        Type   = info.framework,
        Events = info.events,
    },
    Inventory = info.inventory,
}

--------------------------------------------------------------------------------
-- Live values
--
-- PlayerData and isPlayerLoaded are resolved on access instead of being copied
-- once, so a consumer reading MSK.Bridge.PlayerData never works on a snapshot
-- taken at resource start. Client only: on the server a single "the player"
-- does not exist.
--------------------------------------------------------------------------------
if not IsDuplicityVersion() then
    setmetatable(Bridge, {
        __index = function(_, key)
            if key == 'PlayerData' then
                return exports.msk_core:GetPlayerData() or {}
            elseif key == 'isPlayerLoaded' then
                return exports.msk_core:IsPlayerLoaded()
            end

            return nil
        end,
    })
end

return Bridge
