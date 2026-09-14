--------------------------------------------------------------------------------
-- MSK.Menu (client)
--
-- A keyboard menu (arrow keys, Enter, Backspace) without NUI focus, so the
-- player can keep walking or driving while it is open.
--
--   MSK.Menu.Register('tuning', {
--       title = 'Tuning',
--       position = 'top-left',
--       onSelected = function(index, item, args) end,       -- selection moved
--       onSideScroll = function(index, scrollIndex, args) end,
--       onCheck = function(index, checked, args) end,
--       onClose = function(key) end,                        -- 'cancel', 'select', 'replace', 'forced' or your own key
--       items = {
--           { label = 'Color', values = { 'Black', 'White' }, defaultIndex = 1, args = { mod = 'color' } },
--           { label = 'Neon', checked = false },
--           { label = 'Engine', icon = 'gear', iconAnimation = 'spin', progress = 80, close = false },
--       },
--   }, function(selected, scrollIndex, args, checked)
--       -- runs when an item is chosen with Enter (also possible as data.onSelect)
--   end)
--
--   MSK.Menu.Show('tuning', 2)                        -- start on the second item
--   MSK.Menu.SetOptions('tuning', { label = 'Engine' }, 3)   -- replace one item (or all without index)
--   MSK.Menu.Hide(false)                              -- close without onClose
--
-- Items may also carry their own onSelect(args), event and serverEvent.
-- Choosing an item closes the menu first (unless close = false) and runs the
-- callbacks afterwards, so a callback can open the next menu.
--
-- A menu belongs to the resource that registered it: it is removed when that
-- resource stops, and closed if it is open at that moment.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Menu = {}

if IS_CORE then
    -- Control ids (arrow keys plus enter/backspace). Deliberately NO
    -- SetNuiFocus, so the player can keep walking or driving while it is open.
    local CTRL_UP, CTRL_DOWN = 172, 173
    local CTRL_LEFT, CTRL_RIGHT = 174, 175
    local CTRL_SELECT, CTRL_BACK = 176, 177

    -- Back (177) includes Escape, which would open the pause menu on top.
    local CTRL_PAUSE, CTRL_PAUSE_ALTERNATE = 199, 200

    local ANIMATIONS = {
        spin = true, spinPulse = true, spinReverse = true, beat = true, beatFade = true,
        bounce = true, fade = true, flip = true, shake = true,
    }

    local menus = {}          -- id -> data (title, items, position, canClose, disableInput, callbacks, owner)
    local currentId = nil
    local isOpen = false

    -- A generation counter instead of a threadRunning flag. Menu.Show calls
    -- Menu.Hide, and Hide calls data.onClose. If that callback yields, the old
    -- input thread sees isOpen == false in between, ends itself and clears the
    -- flag even though the new menu is already open. After that no thread was
    -- left and the menu stopped accepting keys. With a generation, every Show
    -- starts its own thread and the older one ends on its own.
    local threadGeneration = 0

    -- Counter for inline menus without an id of their own, replacing
    -- GetGameTimer(): two of them in the same millisecond shared one id.
    local inlineCounter = 0

    -- Runtime state kept apart from the registry, so a repeated Show starts fresh.
    local runtime = { selected = 1, valueIndex = {}, checked = {} }

    local function copy(tbl)
        local result = {}
        for key, value in pairs(tbl) do result[key] = value end
        return result
    end

    -- Copies, so the caller's tables are never changed by the menu.
    local function normalizeItems(items)
        local out = {}
        if type(items) ~= 'table' then return out end
        for i = 1, #items do
            if type(items[i]) == 'table' then out[#out + 1] = copy(items[i]) end
        end
        return out
    end

    -- Runs a callback of a menu. An error in one of them used to end the input
    -- thread: the menu stayed on screen and never reacted to a key again.
    local function safeCall(data, name, fn, ...)
        if fn == nil then return end

        local ok, err = pcall(fn, ...)
        if not ok then
            MSK.Logging('error', ('Menu "%s" of "%s": %s failed: %s'):format(tostring(data.id), tostring(data.owner), name, err))
        end
    end

    local function serializeItems(data)
        local out = {}
        for i, item in ipairs(data.items) do
            local values
            if type(item.values) == 'table' then
                values = {}
                for vi, v in ipairs(item.values) do
                    if type(v) == 'table' then
                        values[vi] = { label = v.label or v[1] or '', description = v.description }
                    else
                        values[vi] = { label = tostring(v) }
                    end
                end

                -- The values can shrink through Update or SetOptions; a stored
                -- index past the end showed an empty value.
                local count = #values
                if count > 0 then
                    local index = math.min(math.max(runtime.valueIndex[i] or 1, 1), count)
                    runtime.valueIndex[i] = index
                end
            end

            out[i] = {
                index = i,
                id = item.id,
                label = item.label,
                description = item.description,
                icon = item.icon,
                iconColor = item.iconColor,
                iconAnimation = ANIMATIONS[item.iconAnimation] and item.iconAnimation or nil,
                disabled = item.disabled,
                checked = runtime.checked[i],
                progress = item.progress,
                colorScheme = item.colorScheme,
                values = values,
                valueIndex = runtime.valueIndex[i],
            }
        end
        return out
    end

    local function refresh()
        if not isOpen then return end
        SendNUIMessage({
            action = 'updateMenu',
            selected = runtime.selected,
            items = serializeItems(menus[currentId]),
        })
    end

    -- Finds the first row that is not disabled, from start in direction dir.
    local function firstSelectable(items, start, dir)
        local count = #items
        if count == 0 then return 1 end
        local i = start
        for _ = 1, count do
            if i < 1 then i = count elseif i > count then i = 1 end
            if not items[i].disabled then return i end
            i = i + dir
        end
        return start
    end

    local function buildRuntime(data, startIndex)
        local state = { selected = 1, valueIndex = {}, checked = {} }

        for i, item in ipairs(data.items) do
            state.valueIndex[i] = item.defaultIndex or 1
            state.checked[i] = item.checked
        end

        local count = #data.items
        local start = tonumber(startIndex) or data.startIndex or data.defaultSelected or 1
        if start > count then start = count end
        if start < 1 then start = 1 end

        state.selected = firstSelectable(data.items, start, 1)
        return state
    end

    local function register(id, data, cb, owner)
        local entry = copy(data or {})
        entry.id = id
        entry.items = normalizeItems(entry.items or entry.options)
        entry.options = nil
        entry.cb = cb or entry.onSelect
        entry.owner = owner
        menus[id] = entry
        return entry
    end

    ---@param id string
    ---@param data table
    ---@param cb? fun(selected: number, scrollIndex?: number, args?: any, checked?: boolean)
    function Menu.Register(id, data, cb)
        if type(id) ~= 'string' then return end

        local entry = register(id, data, cb, GetInvokingResource() or 'msk_core')

        -- Re-registering the open menu shows the new version right away.
        if isOpen and currentId == id then
            runtime = buildRuntime(entry, runtime.selected)
            refresh()
        end

        return entry
    end
    MSK.RegisterMenu = Menu.Register
    exports('RegisterMenu', Menu.Register)

    -- Navigation is module-internal and does NOT belong on the public
    -- MSK.Menu table (the consumer branch does not know it anyway).
    local function move(dir)
        local data = menus[currentId]
        local count = #data.items
        if count == 0 then return end
        local i = runtime.selected
        for _ = 1, count do
            i = i + dir
            if i < 1 then i = count elseif i > count then i = 1 end
            if not data.items[i].disabled then break end
        end
        if i == runtime.selected then return end
        runtime.selected = i
        refresh()
        local item = data.items[i]
        safeCall(data, 'onSelected', data.onSelected, i, item, item.args)
    end

    local function sideScroll(dir)
        local data = menus[currentId]
        local item = data.items[runtime.selected]
        if not item or type(item.values) ~= 'table' or #item.values == 0 then return end
        local n = #item.values
        local vi = (runtime.valueIndex[runtime.selected] or 1) + dir
        if vi < 1 then vi = n elseif vi > n then vi = 1 end
        runtime.valueIndex[runtime.selected] = vi
        refresh()
        safeCall(data, 'onSideScroll', data.onSideScroll, runtime.selected, vi, item.args)
    end

    local function selectRow()
        local data = menus[currentId]
        local selected = runtime.selected
        local item = data.items[selected]
        if not item or item.disabled then return end

        -- Checkbox: toggle it, the menu stays open
        if item.checked ~= nil then
            runtime.checked[selected] = not runtime.checked[selected]
            refresh()
            safeCall(data, 'onCheck', data.onCheck, selected, runtime.checked[selected], item.args)
            return
        end

        local scrollIndex = type(item.values) == 'table' and runtime.valueIndex[selected] or nil
        local checked = runtime.checked[selected]

        -- Close first, then run the callbacks. The other way round, a callback
        -- that opened the next menu saw it closed again by this very line.
        if item.close ~= false then
            Menu.Hide('select')
        end

        safeCall(data, 'onSelect', item.onSelect, item.args)
        safeCall(data, 'menu callback', data.cb, selected, scrollIndex, item.args, checked)
        if item.event then TriggerEvent(item.event, item.args) end
        if item.serverEvent then TriggerServerEvent(item.serverEvent, item.args) end
    end

    local function startThread()
        threadGeneration = threadGeneration + 1
        local myGeneration = threadGeneration

        CreateThread(function()
            while isOpen and threadGeneration == myGeneration do
                Wait(0)
                local data = menus[currentId]
                if isOpen and threadGeneration == myGeneration and data and not data.disableInput then
                    -- Only the navigation controls in use are blocked,
                    -- everything else (walking, driving, ...) stays live.
                    DisableControlAction(0, CTRL_UP, true)
                    DisableControlAction(0, CTRL_DOWN, true)
                    DisableControlAction(0, CTRL_LEFT, true)
                    DisableControlAction(0, CTRL_RIGHT, true)
                    DisableControlAction(0, CTRL_SELECT, true)
                    DisableControlAction(0, CTRL_BACK, true)

                    if data.canClose ~= false then
                        DisableControlAction(0, CTRL_PAUSE, true)
                        DisableControlAction(0, CTRL_PAUSE_ALTERNATE, true)
                    end

                    if IsDisabledControlJustPressed(0, CTRL_UP) then
                        move(-1)
                    elseif IsDisabledControlJustPressed(0, CTRL_DOWN) then
                        move(1)
                    elseif IsDisabledControlJustPressed(0, CTRL_LEFT) then
                        sideScroll(-1)
                    elseif IsDisabledControlJustPressed(0, CTRL_RIGHT) then
                        sideScroll(1)
                    elseif IsDisabledControlJustPressed(0, CTRL_SELECT) then
                        selectRow()
                    elseif IsDisabledControlJustPressed(0, CTRL_BACK) then
                        if data.canClose ~= false then Menu.Hide('cancel') end
                    end
                end
            end
        end)
    end

    ---@param idOrData string|table
    ---@param startIndex? number
    function Menu.Show(idOrData, startIndex)
        local id, data

        if type(idOrData) == 'table' then
            if idOrData.id then
                id = idOrData.id
            else
                inlineCounter = inlineCounter + 1
                id = ('inline:%d'):format(inlineCounter)
            end

            data = register(id, idOrData, nil, GetInvokingResource() or 'msk_core')
            data.isInline = idOrData.id == nil
        else
            id = idOrData
            data = menus[id]
        end

        -- Checked before closing the current menu: a typo in the id no longer
        -- closes a menu the player is using.
        if not data then
            print(('[^3msk_core^0] ShowMenu: unknown menu "^1%s^0"'):format(tostring(id)))
            return
        end

        if isOpen then Menu.Hide('replace') end

        currentId = id
        isOpen = true
        runtime = buildRuntime(data, startIndex)

        SendNUIMessage({
            action = 'openMenu',
            id = id,
            title = data.title or '',
            position = data.position or 'top-left',
            selected = runtime.selected,
            items = serializeItems(data),
        })

        startThread()
    end
    MSK.ShowMenu = Menu.Show
    exports('ShowMenu', Menu.Show)

    -- Merges updatedData into the item with id == dataId (partial); refreshes live when open.
    function Menu.Update(menuId, dataId, updatedData)
        updatedData = updatedData or {}

        local data = menus[menuId]
        if not data or not data.items then
            print(('[^3msk_core^0] UpdateMenu: unknown menu "^1%s^0"'):format(tostring(menuId)))
            return
        end

        local idx, target
        for i, item in ipairs(data.items) do
            if item.id == dataId then idx, target = i, item break end
        end
        if not target then
            print(('[^3msk_core^0] UpdateMenu: item "^1%s^0" not found in "^1%s^0"'):format(tostring(dataId), tostring(menuId)))
            return
        end

        for k, v in pairs(updatedData) do
            target[k] = v
        end

        if isOpen and currentId == menuId then
            if updatedData.checked ~= nil then runtime.checked[idx] = updatedData.checked end
            if updatedData.defaultIndex ~= nil then runtime.valueIndex[idx] = updatedData.defaultIndex end
            refresh()
        end
    end
    MSK.UpdateMenu = Menu.Update
    exports('UpdateMenu', Menu.Update)

    ---Replaces all items, or with `index` only that one. An open menu updates
    ---right away and keeps its selection where possible.
    ---@param menuId string
    ---@param options table a list of items, or one item when index is given
    ---@param index? number
    function Menu.SetOptions(menuId, options, index)
        local data = menus[menuId]
        if not data then
            print(('[^3msk_core^0] SetMenuOptions: unknown menu "^1%s^0"'):format(tostring(menuId)))
            return
        end

        if type(options) ~= 'table' then
            print(('[^3msk_core^0] SetMenuOptions: options for "^1%s^0" have to be a table'):format(tostring(menuId)))
            return
        end

        if index ~= nil then
            index = tonumber(index)

            if not index or index < 1 or index > #data.items + 1 then
                print(('[^3msk_core^0] SetMenuOptions: index "^1%s^0" is out of range for "^1%s^0"'):format(tostring(index), tostring(menuId)))
                return
            end

            data.items[index] = copy(options)
        else
            data.items = normalizeItems(options)
        end

        if isOpen and currentId == menuId then
            if index then
                runtime.valueIndex[index] = data.items[index].defaultIndex or 1
                runtime.checked[index] = data.items[index].checked
                runtime.selected = firstSelectable(data.items, math.min(runtime.selected, #data.items), 1)
            else
                runtime = buildRuntime(data, runtime.selected)
            end

            refresh()
        end
    end
    MSK.SetMenuOptions = Menu.SetOptions
    exports('SetMenuOptions', Menu.SetOptions)

    ---Closes the open menu. `key` is handed to onClose; false closes without
    ---calling onClose at all.
    ---@param key? string|false
    function Menu.Hide(key)
        if not isOpen then return end
        local data = menus[currentId]
        local closedId = currentId
        isOpen = false
        currentId = nil
        SendNUIMessage({ action = 'closeMenu' })

        -- An inline menu belongs to nobody and is never opened by id again.
        -- Without this cleanup, `menus` grew with every single call to
        -- MSK.ShowMenu(table) and kept growing for the whole session.
        if data and data.isInline then
            menus[closedId] = nil
        end

        if data and key ~= false then
            safeCall(data, 'onClose', data.onClose, key or 'forced')
        end
    end
    Menu.Close = Menu.Hide -- Alias
    MSK.HideMenu = Menu.Hide
    exports('HideMenu', Menu.Hide)
    RegisterNetEvent('msk_core:hideMenu', function() Menu.Hide('forced') end)

    function Menu.GetOpen()
        return currentId
    end
    MSK.GetOpenMenu = Menu.GetOpen
    exports('GetOpenMenu', Menu.GetOpen)

    -- Server -> client. Same serialisation limit as the context menu:
    -- functions do not survive the network, so use event/serverEvent.
    MSK.Register('msk_core:menu', function(source, idOrData, startIndex)
        return Menu.Show(idOrData, startIndex)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() == resource then
            Menu.Hide('forced')
            return
        end

        -- Menus of a stopped resource point their callbacks into a resource
        -- that no longer runs. Close the open one and forget all of them.
        local open = menus[currentId]
        if isOpen and open and open.owner == resource then
            Menu.Hide('forced')
        end

        for id, data in pairs(menus) do
            if data.owner == resource then
                menus[id] = nil
            end
        end
    end)

    MSK.Menu = setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Menu
else
    function Menu.Register(...) return exports.msk_core:RegisterMenu(...) end
    function Menu.Show(...) return exports.msk_core:ShowMenu(...) end
    function Menu.Update(...) return exports.msk_core:UpdateMenu(...) end
    function Menu.SetOptions(...) return exports.msk_core:SetMenuOptions(...) end
    function Menu.Hide(...) return exports.msk_core:HideMenu(...) end
    function Menu.GetOpen() return exports.msk_core:GetOpenMenu() end
    Menu.Close = Menu.Hide -- Alias

    return setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
end
