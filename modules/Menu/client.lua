local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Menu = {}

if IS_CORE then
    -- Control-IDs (Pfeiltasten + Enter/Backspace). Bewusst KEIN SetNuiFocus,
    -- damit der Spieler waehrend des Menues weiter laufen/fahren kann.
    local CTRL_UP, CTRL_DOWN = 172, 173
    local CTRL_LEFT, CTRL_RIGHT = 174, 175
    local CTRL_SELECT, CTRL_BACK = 176, 177

    local menus = {}          -- id -> data (title, items, position, canClose, disableInput, callbacks)
    local currentId = nil
    local isOpen = false
    local threadRunning = false

    -- Laufzeit-State getrennt von der Registry, damit ein erneutes Show frisch startet.
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

    -- Erste nicht-deaktivierte Zeile ab start in Richtung dir finden.
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

    function Menu.Move(dir)
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

    function Menu.SideScroll(dir)
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

    function Menu.Select()
        local data = menus[currentId]
        local item = data.items[runtime.selected]
        if not item or item.disabled then return end

        -- Checkbox: umschalten, Menue bleibt offen
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
            Menu.Close('select')
        end
    end

    local function startThread()
        if threadRunning then return end
        threadRunning = true
        CreateThread(function()
            while isOpen do
                Wait(0)
                local data = menus[currentId]
                if data and not data.disableInput then
                    -- Nur die genutzten Nav-Controls sperren, alles andere
                    -- (Laufen, Fahren, ...) bleibt aktiv.
                    DisableControlAction(0, CTRL_UP, true)
                    DisableControlAction(0, CTRL_DOWN, true)
                    DisableControlAction(0, CTRL_LEFT, true)
                    DisableControlAction(0, CTRL_RIGHT, true)
                    DisableControlAction(0, CTRL_SELECT, true)
                    DisableControlAction(0, CTRL_BACK, true)

                    if IsDisabledControlJustPressed(0, CTRL_UP) then
                        Menu.Move(-1)
                    elseif IsDisabledControlJustPressed(0, CTRL_DOWN) then
                        Menu.Move(1)
                    elseif IsDisabledControlJustPressed(0, CTRL_LEFT) then
                        Menu.SideScroll(-1)
                    elseif IsDisabledControlJustPressed(0, CTRL_RIGHT) then
                        Menu.SideScroll(1)
                    elseif IsDisabledControlJustPressed(0, CTRL_SELECT) then
                        Menu.Select()
                    elseif IsDisabledControlJustPressed(0, CTRL_BACK) then
                        if data.canClose ~= false then Menu.Close('cancel') end
                    end
                end
            end
            threadRunning = false
        end)
    end

    function Menu.Show(idOrData)
        if isOpen then Menu.Close('replace') end

        local id, data
        if type(idOrData) == 'table' then
            data = idOrData
            id = data.id or ('inline:' .. GetGameTimer())
            Menu.Register(id, data)
            data = menus[id]
        else
            id = idOrData
            data = menus[id]
        end

        if not data then
            print(('[^3msk_core^0] ShowMenu: unbekanntes Menue "^1%s^0"'):format(tostring(id)))
            return
        end

        currentId = id
        isOpen = true

        -- Laufzeit-State frisch aufbauen
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

    -- Merged updatedData in das Item mit id == dataId (partiell); live-Refresh falls offen.
    function Menu.Update(menuId, dataId, updatedData)
        local data = menus[menuId]
        if not data or not data.items then
            print(('[^3msk_core^0] UpdateMenu: unbekanntes Menue "^1%s^0"'):format(tostring(menuId)))
            return
        end

        local idx, target
        for i, item in ipairs(data.items) do
            if item.id == dataId then idx, target = i, item break end
        end
        if not target then
            print(('[^3msk_core^0] UpdateMenu: Item "^1%s^0" in "^1%s^0" nicht gefunden'):format(tostring(dataId), tostring(menuId)))
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

    function Menu.Close(key)
        if not isOpen then return end
        local data = menus[currentId]
        isOpen = false
        currentId = nil
        SendNUIMessage({ action = 'closeMenu' })
        if data and data.onClose then data.onClose(key or 'forced') end
    end
    MSK.HideMenu = function(key) Menu.Close(key or 'forced') end
    exports('HideMenu', MSK.HideMenu)
    RegisterNetEvent('msk_core:hideMenu', function() Menu.Close('forced') end)

    function Menu.GetOpen()
        return currentId
    end
    MSK.GetOpenMenu = Menu.GetOpen
    exports('GetOpenMenu', Menu.GetOpen)

    -- Server -> Client. Gleiche Serialisierungs-Einschraenkung wie beim Context:
    -- Funktionen ueberleben das Netzwerk nicht -> event/serverEvent nutzen.
    MSK.Register('msk_core:menu', function(source, idOrData)
        return Menu.Show(idOrData)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if GetCurrentResourceName() ~= resource then return end
        Menu.Close('forced')
    end)

    MSK.Menu = setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
    return MSK.Menu
else
    function Menu.Register(...) return exports.msk_core:RegisterMenu(...) end
    function Menu.Show(...) return exports.msk_core:ShowMenu(...) end
    function Menu.Update(...) return exports.msk_core:UpdateMenu(...) end
    function Menu.Close(...) return exports.msk_core:HideMenu(...) end
    function Menu.GetOpen() return exports.msk_core:GetOpenMenu() end

    return setmetatable(Menu, {
        __call = function(self, ...) return self.Show(...) end
    })
end
