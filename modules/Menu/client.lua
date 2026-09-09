local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Menu = {}

if IS_CORE then
    -- Control ids (arrow keys plus enter/backspace). Deliberately NO
    -- SetNuiFocus, so the player can keep walking or driving while it is open.
    local CTRL_UP, CTRL_DOWN = 172, 173
    local CTRL_LEFT, CTRL_RIGHT = 174, 175
    local CTRL_SELECT, CTRL_BACK = 176, 177

    local menus = {}          -- id -> data (title, items, position, canClose, disableInput, callbacks)
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

    local function normalizeItems(items)
        local out = {}
        if type(items) ~= 'table' then return out end
        for i = 1, #items do
            if type(items[i]) == 'table' then out[#out + 1] = items[i] end
        end
        return out
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
            end
            out[i] = {
                index = i,
                id = item.id,
                label = item.label,
                description = item.description,
                icon = item.icon,
                iconColor = item.iconColor,
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

    function Menu.Register(id, data)
        if type(id) ~= 'string' then return end
        data = data or {}
        data.id = id
        data.items = normalizeItems(data.items or data.options)
        menus[id] = data
        return data
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
        if data.onSelected then data.onSelected(i, item, item.args) end
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
        if data.onSideScroll then data.onSideScroll(runtime.selected, vi, item.args) end
    end

    local function selectRow()
        local data = menus[currentId]
        local item = data.items[runtime.selected]
        if not item or item.disabled then return end

        -- Checkbox: toggle it, the menu stays open
        if item.checked ~= nil then
            runtime.checked[runtime.selected] = not runtime.checked[runtime.selected]
            refresh()
            if data.onCheck then data.onCheck(runtime.selected, runtime.checked[runtime.selected], item.args) end
            return
        end

        local shouldClose = item.close ~= false
        if item.onSelect then item.onSelect(item.args) end
        if item.event then TriggerEvent(item.event, item.args) end
        if item.serverEvent then TriggerServerEvent(item.serverEvent, item.args) end

        if shouldClose then
            Menu.Hide('select')
        end
    end

    local function startThread()
        threadGeneration = threadGeneration + 1
        local myGeneration = threadGeneration

        CreateThread(function()
            while isOpen and threadGeneration == myGeneration do
                Wait(0)
                local data = menus[currentId]
                if data and not data.disableInput then
                    -- Only the navigation controls in use are blocked,
                    -- everything else (walking, driving, ...) stays live.
                    DisableControlAction(0, CTRL_UP, true)
                    DisableControlAction(0, CTRL_DOWN, true)
                    DisableControlAction(0, CTRL_LEFT, true)
                    DisableControlAction(0, CTRL_RIGHT, true)
                    DisableControlAction(0, CTRL_SELECT, true)
                    DisableControlAction(0, CTRL_BACK, true)

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

    function Menu.Show(idOrData)
        if isOpen then Menu.Hide('replace') end

        local id, data
        if type(idOrData) == 'table' then
            data = idOrData

            if data.id then
                id = data.id
            else
                inlineCounter = inlineCounter + 1
                id = ('inline:%d'):format(inlineCounter)
                data.isInline = true
            end

            Menu.Register(id, data)
            data = menus[id]
        else
            id = idOrData
            data = menus[id]
        end

        if not data then
            print(('[^3msk_core^0] ShowMenu: unknown menu "^1%s^0"'):format(tostring(id)))
            return
        end

        currentId = id
        isOpen = true

        -- Build the runtime state from scratch
        runtime = { selected = 1, valueIndex = {}, checked = {} }
        for i, item in ipairs(data.items) do
            runtime.valueIndex[i] = item.defaultIndex or 1
            runtime.checked[i] = item.checked
        end
        local start = data.startIndex or data.defaultSelected or 1
        if start < 1 then start = 1 elseif start > #data.items then start = #data.items end
        runtime.selected = firstSelectable(data.items, math.max(start, 1), 1)

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

        for k, v in pairs(updatedData or {}) do
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

        if data and data.onClose then data.onClose(key or 'forced') end
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
    MSK.Register('msk_core:menu', function(source, idOrData)
        return Menu.Show(idOrData)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        Menu.Hide('forced')
    end)

    MSK.Menu = setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Menu
else
    function Menu.Register(...) return exports.msk_core:RegisterMenu(...) end
    function Menu.Show(...) return exports.msk_core:ShowMenu(...) end
    function Menu.Update(...) return exports.msk_core:UpdateMenu(...) end
    function Menu.Hide(...) return exports.msk_core:HideMenu(...) end
    function Menu.GetOpen() return exports.msk_core:GetOpenMenu() end
    Menu.Close = Menu.Hide -- Alias

    return setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
end
