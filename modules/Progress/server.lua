local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Progress = {}

if IS_CORE then
    function Progress.Start(playerId, data, text, color)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:progressbar', playerId, data, text, color)
    end

    function Progress.Stop(playerId)
        if not playerId or playerId <= 0 then return end
        TriggerClientEvent('msk_core:progressbarStop', playerId)
    end

    MSK.Progressbar = Progress.Start -- Backwards compatibility
    exports('Progressbar', Progress.Start)
    exports('ProgressStop', Progress.Stop)

    MSK.Progress = setmetatable(Progress, {
        __call = function(self, ...) return self.Start(...) end
    })
    return MSK.Progress
else
    function Progress.Start(...) return exports.msk_core:Progressbar(...) end
    function Progress.Stop(...) return exports.msk_core:ProgressStop(...) end

    return setmetatable(Progress, {
        __call = function(self, ...) return self.Start(...) end
    })
end
