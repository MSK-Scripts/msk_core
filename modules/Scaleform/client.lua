local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Scaleform = {}

function Scaleform.Show(scaleform, duration)
    if not scaleform then return end
    local draw = true

    MSK.Timeout.Set(duration or 5000, function()
        draw = false
    end)

    while draw do
        Wait(0)
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    end

    SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function Scaleform.FreemodeMessage(title, text, duration)
    local scaleform = MSK.Request.ScaleformMovie("MP_BIG_MESSAGE_FREEMODE")

    BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(text)
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

function Scaleform.PopupWarning(title, text, footer, duration)
    local scaleform = MSK.Request.ScaleformMovie("POPUP_WARNING")

    BeginScaleformMovieMethod(scaleform, "SHOW_POPUP_WARNING")
    ScaleformMovieMethodAddParamFloat(500.0) -- black background
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(text)
    ScaleformMovieMethodAddParamTextureNameString(footer)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

function Scaleform.BreakingNews(title, text, footer, duration)
    local scaleform = MSK.Request.ScaleformMovie("BREAKING_NEWS")

    BeginScaleformMovieMethod(scaleform, "SET_TEXT")
    ScaleformMovieMethodAddParamTextureNameString(text)
    ScaleformMovieMethodAddParamTextureNameString(footer)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "SET_SCROLL_TEXT")
    ScaleformMovieMethodAddParamInt(0) -- top ticker
    ScaleformMovieMethodAddParamInt(0) -- first string -> start at 0
    ScaleformMovieMethodAddParamTextureNameString(title)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, "DISPLAY_SCROLL_TEXT")
    ScaleformMovieMethodAddParamInt(0) -- Top ticker
    ScaleformMovieMethodAddParamInt(0) -- Index of string
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

function Scaleform.TrafficMovie(duration)
    local scaleform = MSK.Request.ScaleformMovie("TRAFFIC_CAM")

    BeginScaleformMovieMethod(scaleform, "PLAY_CAM_MOVIE")
    EndScaleformMovieMethod()

    Scaleform.Show(scaleform, duration)
end

-- Deprecated, kept for old scripts: MSK.ScaleformAnnounce
local warnedResources = {}

local function announce(title, text, typ, duration)
    if typ == 1 then
        Scaleform.FreemodeMessage(title, text, duration)
    elseif typ == 2 then
        Scaleform.PopupWarning(title, text, '', duration)
    end
end

function Scaleform.ScaleformAnnounce(title, text, typ, duration)
    -- Once per resource like the other deprecations, it used to log an error
    -- on every single call.
    local resource = GetInvokingResource() or GetCurrentResourceName()

    if not warnedResources[resource] then
        warnedResources[resource] = true
        MSK.Logging('warn', ('Resource "%s" calls MSK.ScaleformAnnounce, which is deprecated and will be removed in a future version. Use MSK.Scaleform.FreemodeMessage or MSK.Scaleform.PopupWarning instead.'):format(resource))
    end

    announce(title, text, typ, duration)
end

--------------------------------------------------------------------------------
-- Scaleform.New — a handle on any scaleform movie
--
--   local movie = MSK.Scaleform.New('MP_BIG_MESSAGE_FREEMODE')
--   movie:Call('SHOW_SHARD_WASTED_MP_MESSAGE', 'TITLE', 'Text')
--   movie:Render(5000)      -- draws fullscreen for 5 seconds, then disposes
--
-- On a screen in the world (TV, billboard) through a render target:
--   local tv = MSK.Scaleform.New('MOVIE_PLAYER', {
--       renderTarget = { name = 'tvscreen', model = 'prop_tv_flat_01' },
--   })
--   tv:Render()
--
-- Arguments to :Call are sent by their Lua type: integer -> int, float ->
-- float, boolean -> bool, string -> text. Wrap a value to force a type:
--   { int = 5 }, { float = 1 }, { texture = 'CHAR_DEFAULT' }
--
-- The movie lives in the resource that created it. Dispose it when done, or
-- let :Render do that.
--------------------------------------------------------------------------------
local Movie = {}
Movie.__index = Movie

local function pushArgument(value)
    local valueType = type(value)

    if valueType == 'number' then
        if math.type(value) == 'integer' then
            ScaleformMovieMethodAddParamInt(value)
        else
            ScaleformMovieMethodAddParamFloat(value)
        end
    elseif valueType == 'boolean' then
        ScaleformMovieMethodAddParamBool(value)
    elseif valueType == 'string' then
        BeginTextCommandScaleformString('STRING')
        AddTextComponentSubstringPlayerName(value)
        EndTextCommandScaleformString()
    elseif valueType == 'table' then
        if value.int ~= nil then
            ScaleformMovieMethodAddParamInt(math.floor(value.int))
        elseif value.float ~= nil then
            ScaleformMovieMethodAddParamFloat(value.float + 0.0)
        elseif value.texture ~= nil then
            ScaleformMovieMethodAddParamTextureNameString(value.texture)
        else
            error('Unknown scaleform argument table, expected { int = }, { float = } or { texture = }', 3)
        end
    else
        error(('Unsupported scaleform argument of type "%s"'):format(valueType), 3)
    end
end

-- A clear error instead of a native failing on a nil handle.
local function ensureHandle(self, action)
    if not self.handle then
        error(('Scaleform "%s" was disposed, %s is not possible anymore'):format(self.name, action), 3)
    end
end

---Loads a scaleform movie and returns a handle on it. `options` is either the
---load timeout in milliseconds or a table { timeout, renderTarget = { name, model } }.
---@param name string
---@param options? number|{ timeout?: number, renderTarget?: { name: string, model?: string|number } }
function Scaleform.New(name, options)
    assert(type(name) == 'string', 'Parameter "name" has to be a string on function MSK.Scaleform.New')

    local timeout, renderTarget = options, nil

    if type(options) == 'table' then
        timeout = options.timeout
        renderTarget = options.renderTarget
    end

    local movie = setmetatable({
        name = name,
        handle = MSK.Request.ScaleformMovie(name, timeout),
        rendering = false,
        generation = 0,
    }, Movie)

    if renderTarget then
        movie:SetRenderTarget(renderTarget.name, renderTarget.model)
    end

    return movie
end

---Draws the movie onto a named render target of a model in the world instead
---of the screen, e.g. 'tvscreen' on 'prop_tv_flat_01'.
---@param name string
---@param model? string|number the model carrying the render target
function Movie:SetRenderTarget(name, model)
    ensureHandle(self, 'SetRenderTarget')
    assert(type(name) == 'string', 'Parameter "name" has to be a string on function Scaleform:SetRenderTarget')

    self:ReleaseRenderTarget()

    if type(model) == 'string' then model = joaat(model) end

    -- Only a render target registered here is released here again. One that
    -- another script registered stays in use for that script.
    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, false)
        self.ownsRenderTarget = true
    end

    if model and not IsNamedRendertargetLinked(model) then
        LinkNamedRendertarget(model)
    end

    self.renderTargetName = name
    self.renderTarget = GetNamedRendertargetRenderId(name)
end

---Stops drawing onto the render target, the movie draws on screen again.
function Movie:ReleaseRenderTarget()
    if not self.renderTargetName then return end

    if self.ownsRenderTarget then
        ReleaseNamedRendertarget(self.renderTargetName)
    end

    self.renderTargetName, self.renderTarget, self.ownsRenderTarget = nil, nil, nil
end

---True while :Render draws the movie.
---@return boolean
function Movie:IsRendering()
    return self.rendering and self.handle ~= nil
end

---Calls a method of the movie.
---@param method string
---@param ... any
function Movie:Call(method, ...)
    ensureHandle(self, 'Call')
    BeginScaleformMovieMethod(self.handle, method)

    for i = 1, select('#', ...) do
        pushArgument((select(i, ...)))
    end

    EndScaleformMovieMethod()
end

---Calls a method and waits for its return value.
---@param method string
---@param returnType 'int'|'bool'|'string'
---@param ... any
---@return integer|boolean|string|nil
function Movie:CallWithReturn(method, returnType, ...)
    ensureHandle(self, 'CallWithReturn')
    BeginScaleformMovieMethod(self.handle, method)

    for i = 1, select('#', ...) do
        pushArgument((select(i, ...)))
    end

    local handle = EndScaleformMovieMethodReturnValue()
    local deadline = GetGameTimer() + 1000

    while not IsScaleformMovieMethodReturnValueReady(handle) do
        if GetGameTimer() > deadline then return nil end
        Wait(0)
    end

    if returnType == 'bool' then return GetScaleformMovieMethodReturnValueBool(handle) end
    if returnType == 'string' then return GetScaleformMovieMethodReturnValueString(handle) end
    return GetScaleformMovieMethodReturnValueInt(handle)
end

---Draws one frame. Without arguments fullscreen, otherwise at the centre
---position `x`/`y` with size `width`/`height` (all 0..1 screen units).
function Movie:Draw(x, y, width, height)
    ensureHandle(self, 'Draw')

    if self.renderTarget then
        SetTextRenderId(self.renderTarget)
        SetScriptGfxDrawOrder(4)
        SetScriptGfxDrawBehindPausemenu(true)
        SetScaleformFitRendertarget(self.handle, true)
    end

    if x then
        DrawScaleformMovie(self.handle, x, y, width, height, 255, 255, 255, 255, 0)
    else
        DrawScaleformMovieFullscreen(self.handle, 255, 255, 255, 255, 0)
    end

    if self.renderTarget then
        SetTextRenderId(GetDefaultScriptRendertargetRenderId())
    end
end

---Draws the movie every frame in its own thread, fullscreen or at `area`
---({ x, y, width, height }). With `duration` it stops and disposes itself
---afterwards; without, it runs until :Stop or :Dispose.
---@param duration? number
---@param area? { x: number, y: number, width: number, height: number }
function Movie:Render(duration, area)
    ensureHandle(self, 'Render')
    self.generation = self.generation + 1
    local generation = self.generation
    self.rendering = true

    local deadline = duration and (GetGameTimer() + duration)

    CreateThread(function()
        while self.rendering and self.generation == generation do
            if deadline and GetGameTimer() >= deadline then
                self:Dispose()
                return
            end

            if area then
                self:Draw(area.x, area.y, area.width, area.height)
            else
                self:Draw()
            end

            Wait(0)
        end
    end)
end

---Stops :Render. The movie stays loaded and can be rendered again.
function Movie:Stop()
    self.rendering = false
    self.generation = self.generation + 1
end

---Stops rendering and releases the movie. The handle is unusable afterwards.
function Movie:Dispose()
    self:Stop()
    self:ReleaseRenderTarget()

    if self.handle then
        SetScaleformMovieAsNoLongerNeeded(self.handle)
        self.handle = nil
    end
end

if IS_CORE then
    RegisterNetEvent("msk_core:freemodeMessage", Scaleform.FreemodeMessage)
    RegisterNetEvent("msk_core:popupWarning", Scaleform.PopupWarning)
    RegisterNetEvent("msk_core:breakingNews", Scaleform.BreakingNews)
    RegisterNetEvent("msk_core:trafficMovie", Scaleform.TrafficMovie)
    -- The server already warned the calling resource, the event itself does not.
    RegisterNetEvent("msk_core:scaleformNotification", announce)
end

return Scaleform
