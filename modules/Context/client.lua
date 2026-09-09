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

    -- options may arrive as an array OR as a map (key = id). Internally it
    -- always becomes a clean array.
    local function normalizeOptions(options)
        local out = {}
        if type(options) ~= 'table' then return out end

        if options[1] ~= nil or next(options) == nil then
            -- Array (or empty)
            for i = 1, #options do
                if type(options[i]) == 'table' then out[#out + 1] = options[i] end
            end
        else
            -- Map: the key becomes the id when the option has none
            for k, opt in pairs(options) do
                if type(opt) == 'table' then
                    if opt.id == nil and type(k) == 'string' then opt.id = k end
                    out[#out + 1] = opt
                end
            end
        end
        return out
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
                image = opt.image,
                arrow = opt.arrow or opt.menu ~= nil,
                disabled = opt.disabled,
                readOnly = opt.readOnly,
                progress = opt.progress,
                colorScheme = opt.colorScheme,
                metadata = opt.metadata,
            }
        end
        return out
    end

    function Context.Register(id, data)
        if type(id) ~= 'string' then return end
        data = data or {}
        data.id = id
        data.options = normalizeOptions(data.options)
        contexts[id] = data
        return data
    end
    MSK.RegisterContext = Context.Register
    exports('RegisterContext', Context.Register)

    function Context.Show(idOrData)
        local id, data

        if type(idOrData) == 'table' then
            -- Inline menu: register it on the fly
            data = idOrData

            if data.id then
                id = data.id
            else
                inlineCounter = inlineCounter + 1
                id = ('inline:%d'):format(inlineCounter)
                data.isInline = true
            end

            Context.Register(id, data)
            data = contexts[id]
        else
            id = idOrData
            data = contexts[id]
        end

        if not data then
            print(('[^3msk_core^0] ShowContext: unknown context menu "^1%s^0"'):format(tostring(id)))
            return
        end

        currentId = id
        isOpen = true

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

        if fireExit and data and data.onExit then data.onExit() end
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

    -- NUI -> Lua
    RegisterNUICallback('contextSelect', function(data)
        local ctx = contexts[currentId]
        if not ctx then return end
        local opt = ctx.options and ctx.options[data.index]
        if not opt or opt.disabled or opt.readOnly then return end

        if opt.menu then
            -- Drill down into the submenu (focus stays where it is)
            Context.Show(opt.menu)
            return
        end

        -- Final selection: close first, then fire
        Context.Hide(false)
        if opt.onSelect then opt.onSelect(opt.args) end
        if opt.event then TriggerEvent(opt.event, opt.args) end
        if opt.serverEvent then TriggerServerEvent(opt.serverEvent, opt.args) end
    end)

    RegisterNUICallback('contextBack', function()
        local ctx = contexts[currentId]
        if not ctx then return end
        if ctx.menu then
            if ctx.onBack then ctx.onBack() end
            Context.Show(ctx.menu)
        else
            Context.Hide(true)
        end
    end)

    RegisterNUICallback('closeContext', function()
        Context.Hide(true)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        Context.Hide(false)
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
