--------------------------------------------------------------------------------
-- MSK.Context (client)
--
--   MSK.Context.Register('garage', {
--       title = 'Garage ~g~Pillbox~s~',
--       position = 'right',              -- center, left, right, top, bottom, top-left, ...
--       canClose = true,
--       onExit = function() end,
--       options = {
--           { title = 'Vehicles', icon = 'car', menu = 'garage_vehicles' },
--           { title = 'Repair', icon = 'wrench', iconAnimation = 'shake', progress = 40,
--             metadata = { 'Costs $250', { label = 'Engine', value = '40%', progress = 40 } },
--             onSelect = function(args) end, args = { plate = 'MSK 123' } },
--       },
--   })
--   MSK.Context.Show('garage')
--
-- options may be a list or a map (key = id). A map is sorted by its keys, so
-- the order stays the same on every call.
-- metadata may be a list of strings, a list of { label, value, progress,
-- colorScheme } or a map of label = value.
--
-- A menu belongs to the resource that registered it: it is removed when that
-- resource stops, and closed if it is open at that moment.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Context = {}

if IS_CORE then
    -- Registered context menus (id -> data) plus the currently open state.
    local contexts = {}
    local currentId = nil
    local isOpen = false

    -- Counter for inline menus that carry no id of their own. This used to be
    -- GetGameTimer(), so two inline menus opened in the same millisecond got
    -- the same id and overwrote each other.
    local inlineCounter = 0

    local ANIMATIONS = {
        spin = true, spinPulse = true, spinReverse = true, beat = true, beatFade = true,
        bounce = true, fade = true, flip = true, shake = true,
    }

    local function copy(tbl)
        local result = {}
        for key, value in pairs(tbl) do result[key] = value end
        return result
    end

    local function sortedKeys(tbl)
        local keys = {}
        for key in pairs(tbl) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        return keys
    end

    -- options may arrive as an array OR as a map (key = id). Internally it
    -- always becomes a clean array of copies: the caller's tables are never
    -- changed, so reusing them for another Register gives the same result.
    local function normalizeOptions(options)
        local out = {}
        if type(options) ~= 'table' then return out end

        if options[1] ~= nil or next(options) == nil then
            for i = 1, #options do
                if type(options[i]) == 'table' then out[#out + 1] = copy(options[i]) end
            end
        else
            -- pairs() has no fixed order, so a map is sorted by its keys.
            -- Otherwise the options could change places between two calls.
            for _, key in ipairs(sortedKeys(options)) do
                local opt = options[key]

                if type(opt) == 'table' then
                    opt = copy(opt)
                    if opt.id == nil and type(key) == 'string' then opt.id = key end
                    out[#out + 1] = opt
                end
            end
        end

        return out
    end

    -- Every metadata form ends up as a list of { label, value, progress,
    -- colorScheme }. A plain list of strings used to reach the NUI as is and
    -- showed up as empty rows.
    local function normalizeMetadata(metadata)
        if type(metadata) ~= 'table' then return nil end

        local out = {}

        local function add(label, entry)
            if type(entry) == 'table' then
                out[#out + 1] = {
                    label = tostring(entry.label or label or ''),
                    value = entry.value ~= nil and tostring(entry.value) or nil,
                    progress = tonumber(entry.progress),
                    colorScheme = type(entry.colorScheme) == 'string' and entry.colorScheme or nil,
                }
            elseif label ~= nil then
                out[#out + 1] = { label = tostring(label), value = entry ~= nil and tostring(entry) or nil }
            elseif entry ~= nil then
                out[#out + 1] = { label = tostring(entry) }
            end
        end

        if metadata[1] ~= nil then
            for i = 1, #metadata do
                add(nil, metadata[i])
            end
        else
            for _, key in ipairs(sortedKeys(metadata)) do
                add(key, metadata[key])
            end
        end

        return #out > 0 and out or nil
    end

    -- Builds the serialisable option list that goes to the NUI. Functions
    -- (onSelect and the like) stay in Lua and do NOT cross over.
    local function serialize(data)
        local out = {}
        for i, opt in ipairs(data.options) do
            out[i] = {
                index = i,
                id = opt.id,
                title = opt.title,
                description = opt.description,
                icon = opt.icon,
                iconColor = opt.iconColor,
                iconAnimation = ANIMATIONS[opt.iconAnimation] and opt.iconAnimation or nil,
                image = opt.image,
                arrow = opt.arrow or opt.menu ~= nil,
                disabled = opt.disabled,
                readOnly = opt.readOnly,
                progress = opt.progress,
                colorScheme = opt.colorScheme,
                metadata = normalizeMetadata(opt.metadata),
            }
        end
        return out
    end

    -- Runs a callback of a menu. An error in a script's callback used to end
    -- the NUI callback half way, without saying which menu it came from.
    local function safeCall(ctx, name, fn, ...)
        if fn == nil then return end

        local ok, err = pcall(fn, ...)
        if not ok then
            MSK.Logging('error', ('Context menu "%s" of "%s": %s failed: %s'):format(tostring(ctx.id), tostring(ctx.owner), name, err))
        end
    end

    local function register(id, data, owner)
        local entry = copy(data or {})
        entry.id = id
        entry.options = normalizeOptions(entry.options)
        entry.owner = owner
        contexts[id] = entry
        return entry
    end

    local function sendOpen(id, data)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openContext',
            id = id,
            title = data.title or '',
            options = serialize(data),
            canClose = data.canClose ~= false,
            position = data.position or 'center',
            hasBack = data.menu ~= nil,
        })
    end

    function Context.Register(id, data)
        if type(id) ~= 'string' then return end

        local entry = register(id, data, GetInvokingResource() or 'msk_core')

        -- Re-registering the open menu shows the new version right away.
        if isOpen and currentId == id then
            sendOpen(id, entry)
        end

        return entry
    end
    MSK.RegisterContext = Context.Register
    exports('RegisterContext', Context.Register)

    function Context.Show(idOrData)
        local id, data

        if type(idOrData) == 'table' then
            -- Inline menu: register it on the fly
            if idOrData.id then
                id = idOrData.id
            else
                inlineCounter = inlineCounter + 1
                id = ('inline:%d'):format(inlineCounter)
            end

            data = register(id, idOrData, GetInvokingResource() or 'msk_core')
            data.isInline = idOrData.id == nil
        else
            id = idOrData
            data = contexts[id]
        end

        if not data then
            print(('[^3msk_core^0] ShowContext: unknown context menu "^1%s^0"'):format(tostring(id)))
            return
        end

        -- Leaving an inline menu for another one: nobody can ever open the
        -- inline one again, so it would only pile up.
        if isOpen and currentId ~= id then
            local previous = contexts[currentId]
            if previous and previous.isInline then
                contexts[currentId] = nil
            end
        end

        currentId = id
        isOpen = true

        sendOpen(id, data)
    end
    MSK.ShowContext = Context.Show
    exports('ShowContext', Context.Show)

    -- Merges updatedData into the option with id == dataId (partial update).
    -- When that menu is the open one, the NUI is refreshed live.
    function Context.Update(contextId, dataId, updatedData)
        local data = contexts[contextId]
        if not data or not data.options then
            print(('[^3msk_core^0] UpdateContext: unknown context menu "^1%s^0"'):format(tostring(contextId)))
            return
        end

        local target
        for _, opt in ipairs(data.options) do
            if opt.id == dataId then target = opt break end
        end
        if not target then
            print(('[^3msk_core^0] UpdateContext: option "^1%s^0" not found in "^1%s^0"'):format(tostring(dataId), tostring(contextId)))
            return
        end

        for k, v in pairs(updatedData or {}) do
            target[k] = v
        end

        if isOpen and currentId == contextId then
            SendNUIMessage({ action = 'updateContext', options = serialize(data) })
        end
    end
    MSK.UpdateContext = Context.Update
    exports('UpdateContext', Context.Update)

    function Context.Hide(fireExit)
        if not isOpen then return end
        local data = contexts[currentId]
        local closedId = currentId
        isOpen = false
        currentId = nil

        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeContext' })

        -- An inline menu belongs to nobody and is never opened by id again.
        -- Without this cleanup, `contexts` grew with every single call to
        -- MSK.ShowContext(table) and kept growing for the whole session.
        if data and data.isInline then
            contexts[closedId] = nil
        end

        if fireExit and data then
            safeCall(data, 'onExit', data.onExit)
        end
    end
    MSK.HideContext = function(fireExit) Context.Hide(fireExit) end
    exports('HideContext', MSK.HideContext)
    RegisterNetEvent('msk_core:hideContext', function() Context.Hide(false) end)

    function Context.GetOpen()
        return currentId
    end
    MSK.GetOpenContext = Context.GetOpen
    exports('GetOpenContext', Context.GetOpen)

    -- Server -> client: MSK.ShowContext(playerId, idOrData).
    -- Only serialisable data crosses the network. Functions (onSelect/onExit)
    -- do NOT survive it, so reach for event/serverEvent/args instead, or
    -- register the menu on the client first and open it by id.
    MSK.Register('msk_core:context', function(source, idOrData)
        return Context.Show(idOrData)
    end)

    -- NUI -> Lua. Every callback answers the NUI first: without cb() each
    -- click left a request in the NUI that never finished.
    RegisterNUICallback('contextSelect', function(data, cb)
        cb('ok')

        local ctx = contexts[currentId]
        if not ctx then return end

        local opt = ctx.options and ctx.options[tonumber(data and data.index)]
        if not opt or opt.disabled or opt.readOnly then return end

        if opt.menu then
            -- Drill down into the submenu (focus stays where it is)
            Context.Show(opt.menu)
            return
        end

        -- Final selection: close first, then fire
        Context.Hide(false)
        safeCall(ctx, 'onSelect', opt.onSelect, opt.args)
        if opt.event then TriggerEvent(opt.event, opt.args) end
        if opt.serverEvent then TriggerServerEvent(opt.serverEvent, opt.args) end
    end)

    RegisterNUICallback('contextBack', function(_, cb)
        cb('ok')

        local ctx = contexts[currentId]
        if not ctx then return end

        if ctx.menu then
            safeCall(ctx, 'onBack', ctx.onBack)
            Context.Show(ctx.menu)
        else
            Context.Hide(true)
        end
    end)

    RegisterNUICallback('closeContext', function(_, cb)
        cb('ok')
        Context.Hide(true)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() == resource then
            Context.Hide(false)
            return
        end

        -- Menus of a stopped resource point their callbacks into a resource
        -- that no longer runs. Close the open one and forget all of them.
        local open = contexts[currentId]
        if isOpen and open and open.owner == resource then
            Context.Hide(false)
        end

        for id, ctx in pairs(contexts) do
            if ctx.owner == resource then
                contexts[id] = nil
            end
        end
    end)

    MSK.Context = setmetatable(Context, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Context
else
    function Context.Register(...) return exports.msk_core:RegisterContext(...) end
    function Context.Show(...) return exports.msk_core:ShowContext(...) end
    function Context.Update(...) return exports.msk_core:UpdateContext(...) end
    function Context.Hide(...) return exports.msk_core:HideContext(...) end
    function Context.GetOpen() return exports.msk_core:GetOpenContext() end

    return setmetatable(Context, {
        __call = function(self, ...) return self.Show(...) end
    })
end
