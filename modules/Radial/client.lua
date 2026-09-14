--------------------------------------------------------------------------------
-- MSK.Radial (client)
--
-- A radial menu that scripts fill with their own entries. Opened with a key
-- (Config.Radial, the player can rebind it).
--
--   MSK.Radial.Add({
--       id = 'vehicle_menu',
--       label = 'Vehicle',
--       icon = 'car',
--       menu = 'vehicle',                      -- opens a submenu
--   })
--
--   MSK.Radial.Register({
--       id = 'vehicle',
--       title = 'Vehicle',
--       items = {
--           { id = 'engine', label = 'Engine', icon = 'power-off', onSelect = function(menuId, index) ... end },
--           { id = 'doors', label = 'Doors', icon = 'door-open', keepOpen = true, onSelect = ToggleDoors },
--       },
--   })
--
-- Items need an id and a label. icon is a Font Awesome name ('car') or class
-- ('fas fa-car'). onSelect(menuId, index) runs when the item is clicked; the
-- menu closes first unless keepOpen is true. Right click or Backspace goes
-- back one level.
--
-- Items and submenus belong to the resource that added them and disappear
-- when that resource stops.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Radial = {}

if IS_CORE then
    local settings = Config.Radial or {}

    local globalItems = {}
    local menus = {}

    local isOpen = false
    local disabled = false
    local currentMenu = nil
    local history = {}

    -- Camera and attack stay disabled while the cursor is over the menu,
    -- movement keeps working.
    local BLOCKED_CONTROLS = { 1, 2, 24, 25, 68, 69, 70, 91, 92, 106, 140, 141, 142, 257, 263, 264 }

    local function currentItems()
        if currentMenu then
            local menu = menus[currentMenu]
            return menu and menu.items or {}
        end
        return globalItems
    end

    local function normalize(item, owner)
        assert(type(item) == 'table', 'A radial item has to be a table')
        assert(type(item.id) == 'string' and item.id ~= '', 'A radial item needs a string id')
        assert(type(item.label) == 'string', ('Radial item "%s" needs a string label'):format(item.id))

        return {
            id = item.id,
            label = item.label,
            icon = item.icon,
            iconColor = item.iconColor,
            menu = item.menu,
            onSelect = item.onSelect,
            keepOpen = item.keepOpen == true,
            owner = owner,
        }
    end

    local function serialize(items)
        local list = {}

        for i = 1, #items do
            local item = items[i]
            list[i] = {
                index = i,
                label = item.label,
                icon = item.icon,
                iconColor = item.iconColor,
                hasMenu = item.menu ~= nil,
            }
        end

        return list
    end

    local function refresh()
        local items = currentItems()

        if #items == 0 then
            return Radial.Hide()
        end

        local menu = currentMenu and menus[currentMenu]

        SendNUIMessage({
            action = 'openRadial',
            items = serialize(items),
            hasBack = #history > 0,
            title = menu and menu.title or nil,
        })
    end

    function Radial.Show()
        if isOpen or disabled or #globalItems == 0 then return end
        if IsPauseMenuActive() or IsNuiFocused() then return end

        isOpen = true
        currentMenu = nil
        history = {}

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        SetCursorLocation(0.5, 0.5)
        MSK.Controls.Disable(BLOCKED_CONTROLS)

        refresh()
    end

    function Radial.Hide()
        if not isOpen then return end

        isOpen = false
        currentMenu = nil
        history = {}

        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        MSK.Controls.Enable(BLOCKED_CONTROLS)

        SendNUIMessage({ action = 'closeRadial' })
    end

    ---Adds one item or a list of items to the first level. An item with an id
    ---that already exists replaces it.
    ---@param items table|table[]
    function Radial.Add(items)
        assert(type(items) == 'table', 'Parameter "items" has to be a table on function MSK.Radial.Add')

        local owner = GetInvokingResource() or 'msk_core'
        if items.id then items = { items } end

        for i = 1, #items do
            local item = normalize(items[i], owner)
            local replaced = false

            for j = 1, #globalItems do
                if globalItems[j].id == item.id then
                    globalItems[j] = item
                    replaced = true
                    break
                end
            end

            if not replaced then
                globalItems[#globalItems + 1] = item
            end
        end

        if isOpen and not currentMenu then refresh() end
    end

    ---Removes a first-level item by id.
    ---@param id string
    ---@return boolean removed
    function Radial.Remove(id)
        for i = #globalItems, 1, -1 do
            if globalItems[i].id == id then
                table.remove(globalItems, i)
                if isOpen and not currentMenu then refresh() end
                return true
            end
        end

        return false
    end

    ---Removes every first-level item the calling resource added.
    function Radial.Clear()
        local owner = GetInvokingResource() or 'msk_core'

        for i = #globalItems, 1, -1 do
            if globalItems[i].owner == owner then
                table.remove(globalItems, i)
            end
        end

        if isOpen and not currentMenu then refresh() end
    end

    ---Registers a submenu that items can open through their `menu` field.
    ---@param menu { id: string, title?: string, items: table[] }
    function Radial.Register(menu)
        assert(type(menu) == 'table' and type(menu.id) == 'string', 'Field "id" has to be a string on function MSK.Radial.Register')
        assert(type(menu.items) == 'table', 'Field "items" has to be a table on function MSK.Radial.Register')

        local owner = GetInvokingResource() or 'msk_core'
        local items = {}

        for i = 1, #menu.items do
            items[i] = normalize(menu.items[i], owner)
        end

        menus[menu.id] = { id = menu.id, title = menu.title, items = items, owner = owner }

        if isOpen and currentMenu == menu.id then refresh() end
    end

    ---@param id string
    function Radial.Unregister(id)
        menus[id] = nil

        if isOpen and currentMenu == id then
            Radial.Hide()
        end
    end

    ---Disables (true, default) or enables (false) the radial menu.
    ---@param state? boolean
    function Radial.Disable(state)
        disabled = state ~= false
        if disabled then Radial.Hide() end
    end

    ---@return boolean
    function Radial.IsOpen()
        return isOpen
    end

    ---Id of the open submenu, nil on the first level or when closed.
    ---@return string?
    function Radial.GetCurrentId()
        return currentMenu
    end

    RegisterNUICallback('radialSelect', function(data, cb)
        cb('ok')
        if not isOpen then return end

        local index = tonumber(data and data.index)
        local item = index and currentItems()[index]
        if not item then return end

        if item.menu then
            if menus[item.menu] then
                history[#history + 1] = currentMenu or false
                currentMenu = item.menu
                refresh()
            end
            return
        end

        local menuId = currentMenu

        if not item.keepOpen then
            Radial.Hide()
        end

        if item.onSelect then
            local ok, err = pcall(item.onSelect, menuId, index)
            if not ok then
                MSK.Logging('error', ('Radial item "%s" of "%s" failed: %s'):format(item.id, item.owner, err))
            end
        end
    end)

    RegisterNUICallback('radialBack', function(_, cb)
        cb('ok')
        if not isOpen then return end

        if #history == 0 then
            return Radial.Hide()
        end

        currentMenu = table.remove(history) or nil
        refresh()
    end)

    RegisterNUICallback('radialClose', function(_, cb)
        cb('ok')
        Radial.Hide()
    end)

    if settings.enable ~= false then
        MSK.Keybind.Add({
            name = 'msk_core_radial',
            description = 'Open radial menu',
            defaultKey = settings.key or 'Z',
            onPressed = function()
                if isOpen and not settings.hold then
                    Radial.Hide()
                else
                    Radial.Show()
                end
            end,
            onReleased = function()
                if settings.hold then Radial.Hide() end
            end,
        })
    end

    AddEventHandler('onResourceStop', function(resource)
        if resource == 'msk_core' then
            return Radial.Hide()
        end

        local changed = false

        for i = #globalItems, 1, -1 do
            if globalItems[i].owner == resource then
                table.remove(globalItems, i)
                changed = true
            end
        end

        for id, menu in pairs(menus) do
            if menu.owner == resource then
                menus[id] = nil
                changed = true
            end
        end

        if changed and isOpen then
            if currentMenu and not menus[currentMenu] then
                Radial.Hide()
            else
                refresh()
            end
        end
    end)

    exports('AddRadialItem', Radial.Add)
    exports('RemoveRadialItem', Radial.Remove)
    exports('ClearRadialItems', Radial.Clear)
    exports('RegisterRadial', Radial.Register)
    exports('UnregisterRadial', Radial.Unregister)
    exports('ShowRadial', Radial.Show)
    exports('HideRadial', Radial.Hide)
    exports('DisableRadial', Radial.Disable)
    exports('IsRadialOpen', Radial.IsOpen)
    exports('GetRadialId', Radial.GetCurrentId)

    MSK.Radial = Radial
else
    function Radial.Add(items) return exports.msk_core:AddRadialItem(items) end
    function Radial.Remove(id) return exports.msk_core:RemoveRadialItem(id) end
    function Radial.Clear() return exports.msk_core:ClearRadialItems() end
    function Radial.Register(menu) return exports.msk_core:RegisterRadial(menu) end
    function Radial.Unregister(id) return exports.msk_core:UnregisterRadial(id) end
    function Radial.Show() return exports.msk_core:ShowRadial() end
    function Radial.Hide() return exports.msk_core:HideRadial() end
    function Radial.Disable(state) return exports.msk_core:DisableRadial(state) end
    function Radial.IsOpen() return exports.msk_core:IsRadialOpen() end
    function Radial.GetCurrentId() return exports.msk_core:GetRadialId() end
end

return Radial
