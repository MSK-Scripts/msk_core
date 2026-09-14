--------------------------------------------------------------------------------
-- MSK.Dui (client)
--
-- A web page rendered into a game texture, e.g. for screens, billboards or
-- in-world tablets.
--
--   local screen = MSK.Dui.New({ url = 'https://example.com', width = 1280, height = 720 })
--   screen:ReplaceTexture('prop_tv_flat_01', 'script_rt_tvscreen')
--   screen:SendMessage({ action = 'play', video = 'intro' })
--   ...
--   screen:Remove()
--
-- For a page inside your own resource use 'nui://my_script/html/screen.html'.
-- Every DUI of a resource is removed when that resource stops.
--------------------------------------------------------------------------------
local Dui = {}

local RESOURCE = GetCurrentResourceName()

local instances = {}
local counter = 0

local Instance = {}
Instance.__index = Instance

local MOUSE_BUTTONS = { left = 'left', middle = 'middle', right = 'right' }

---@param data { url: string, width?: number, height?: number }
function Dui.New(data)
    assert(type(data) == 'table' and type(data.url) == 'string', 'Field "url" has to be a string on function MSK.Dui.New')

    counter = counter + 1

    local width = math.floor(tonumber(data.width) or 1280)
    local height = math.floor(tonumber(data.height) or 720)
    local name = ('%s_dui_%s'):format(RESOURCE, counter)

    local duiObject = CreateDui(data.url, width, height)
    local duiHandle = GetDuiHandle(duiObject)
    local txd = CreateRuntimeTxd(name)

    CreateRuntimeTextureFromDuiHandle(txd, name, duiHandle)

    local self = setmetatable({
        id = counter,
        url = data.url,
        width = width,
        height = height,
        duiObject = duiObject,
        duiHandle = duiHandle,
        dictName = name,
        textureName = name,
        replaced = {},
    }, Instance)

    instances[counter] = self
    return self
end

---True once the page has loaded far enough to receive messages.
---@return boolean
function Instance:IsAvailable()
    return self.duiObject ~= nil and IsDuiAvailable(self.duiObject)
end

---@param url string
function Instance:SetUrl(url)
    assert(type(url) == 'string', 'Parameter "url" has to be a string on function Dui:SetUrl')
    self.url = url
    SetDuiUrl(self.duiObject, url)
end

---Sends a message to the page. It arrives there as a window 'message' event
---with the table as event.data.
---@param data table
function Instance:SendMessage(data)
    SendDuiMessage(self.duiObject, json.encode(data))
end

---Shows this page in place of a texture of the game.
---@param originalDict string
---@param originalTexture string
function Instance:ReplaceTexture(originalDict, originalTexture)
    AddReplaceTexture(originalDict, originalTexture, self.dictName, self.textureName)
    self.replaced[#self.replaced + 1] = { originalDict, originalTexture }
end

---Moves the mouse inside the page, in pixels of the page size.
function Instance:MouseMove(x, y)
    SendDuiMouseMove(self.duiObject, math.floor(x), math.floor(y))
end

---@param button? 'left'|'middle'|'right'
function Instance:MouseDown(button)
    SendDuiMouseDown(self.duiObject, MOUSE_BUTTONS[button] or 'left')
end

---@param button? 'left'|'middle'|'right'
function Instance:MouseUp(button)
    SendDuiMouseUp(self.duiObject, MOUSE_BUTTONS[button] or 'left')
end

---@param deltaY number
---@param deltaX? number
function Instance:MouseWheel(deltaY, deltaX)
    SendDuiMouseWheel(self.duiObject, math.floor(deltaY), math.floor(deltaX or 0))
end

---Restores replaced textures and destroys the page.
function Instance:Remove()
    if not self.duiObject then return end

    for i = 1, #self.replaced do
        RemoveReplaceTexture(self.replaced[i][1], self.replaced[i][2])
    end
    self.replaced = {}

    DestroyDui(self.duiObject)
    self.duiObject = nil
    instances[self.id] = nil
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end

    for _, instance in pairs(instances) do
        instance:Remove()
    end
end)

return Dui
