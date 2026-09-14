--------------------------------------------------------------------------------
-- MSK.Hook
--
-- Lets other resources hook into what a script is about to do and veto it.
--
--   -- in the script that owns the action:
--   if not MSK.Hook.Trigger('garage:parkVehicle', { source = source, plate = plate }) then
--       return -- some hook refused
--   end
--
--   -- in any other resource:
--   MSK.Hook.Register('garage:parkVehicle', function(payload)
--       if payload.plate == 'ADMIN' then return false end
--   end)
--
-- A hook refuses by returning exactly false; any other return value lets the
-- action through. Hooks run by priority (higher first), equal priorities in
-- the order they were registered. A hook that raises an error is logged and
-- skipped, it does not block the action.
--
-- The registry lives in msk_core, one per side. Hooks of a resource are removed
-- when that resource stops, so no call ever lands in a stopped resource.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Hook = {}

if IS_CORE then
    local hooks = {}      -- [event] = { entry, ... } sorted by priority
    local byId = {}       -- [id] = entry
    local nextId = 0

    ---@param event string
    ---@param cb fun(payload: any): boolean?
    ---@param options? { priority?: number }
    ---@return integer id
    function Hook.Register(event, cb, options)
        assert(type(event) == 'string' and event ~= '', 'Parameter "event" has to be a non-empty string on function MSK.Hook.Register')
        assert(cb ~= nil, 'Parameter "cb" is nil on function MSK.Hook.Register')

        nextId = nextId + 1

        local entry = {
            id = nextId,
            event = event,
            cb = cb,
            owner = GetInvokingResource() or 'msk_core',
            priority = options and tonumber(options.priority) or 0,
        }

        local list = hooks[event]
        if not list then
            list = {}
            hooks[event] = list
        end

        -- Insert after every entry with the same or a higher priority, so the
        -- registration order holds within one priority.
        local position = #list + 1
        for i = 1, #list do
            if list[i].priority < entry.priority then
                position = i
                break
            end
        end

        table.insert(list, position, entry)
        byId[entry.id] = entry

        return entry.id
    end

    local function removeEntry(entry)
        local list = hooks[entry.event]

        if list then
            for i = 1, #list do
                if list[i] == entry then
                    table.remove(list, i)
                    break
                end
            end

            if #list == 0 then
                hooks[entry.event] = nil
            end
        end

        byId[entry.id] = nil
    end

    ---Removes a hook. Only the resource that registered it may do so.
    ---@param id integer
    ---@return boolean removed
    function Hook.Remove(id)
        local entry = byId[id]
        if not entry then return false end

        local caller = GetInvokingResource() or 'msk_core'
        if caller ~= entry.owner and caller ~= 'msk_core' then
            MSK.Logging('warn', ('Resource "%s" tried to remove hook %s of "%s"'):format(caller, id, entry.owner))
            return false
        end

        removeEntry(entry)
        return true
    end

    ---Runs every hook of `event`. Returns false and the refusing resource as
    ---soon as one hook returns false, otherwise true.
    ---@param event string
    ---@param payload? any
    ---@return boolean allowed, string? refusedBy
    function Hook.Trigger(event, payload)
        local list = hooks[event]
        if not list then return true end

        -- Work on a copy: a hook may register or remove hooks while it runs.
        local snapshot = {}
        for i = 1, #list do snapshot[i] = list[i] end

        for i = 1, #snapshot do
            local entry = snapshot[i]

            if byId[entry.id] then
                local ok, result = pcall(entry.cb, payload)

                if not ok then
                    MSK.Logging('error', ('Hook "%s" of resource "%s" failed: %s'):format(event, entry.owner, result))
                elseif result == false then
                    return false, entry.owner
                end
            end
        end

        return true
    end

    ---@param event string
    ---@return boolean
    function Hook.Has(event)
        return hooks[event] ~= nil
    end

    AddEventHandler('onResourceStop', function(resource)
        for _, entry in pairs(byId) do
            if entry.owner == resource then
                removeEntry(entry)
            end
        end
    end)

    exports('RegisterHook', Hook.Register)
    exports('RemoveHook', Hook.Remove)
    exports('TriggerHook', Hook.Trigger)
    exports('HasHook', Hook.Has)

    MSK.Hook = Hook
else
    function Hook.Register(event, cb, options) return exports.msk_core:RegisterHook(event, cb, options) end
    function Hook.Remove(id) return exports.msk_core:RemoveHook(id) end
    function Hook.Trigger(event, payload) return exports.msk_core:TriggerHook(event, payload) end
    function Hook.Has(event) return exports.msk_core:HasHook(event) end
end

return Hook
