--------------------------------------------------------------------------------
-- MSK.Require
--
-- Loads Lua and JSON files at runtime, from this resource or from another one.
--
--   MSK.Require.Load('shared.utils')                 -- this resource, shared/utils.lua
--   MSK.Require.Load('@my_lib/client/helpers.lua')   -- another resource
--   MSK.Require.Json('data.vehicles')                -- this resource, data/vehicles.json
--
-- Lua modules run once and their return value is cached, like require().
-- A module that returns nothing is cached as true. A module that requires
-- itself, directly or through others, raises an error instead of looping.
--
-- On the client a file can only be read when the resource that owns it lists
-- it in its fxmanifest (files { ... }).
--------------------------------------------------------------------------------
local Require = {}

local RESOURCE = GetCurrentResourceName()

local cache = {}
local loading = {}

---Splits a path into resource and file, adding `extension`.
local function resolve(path, extension)
    assert(type(path) == 'string' and path ~= '', 'Parameter "path" has to be a non-empty string on function MSK.Require')

    local resource, file = RESOURCE, path

    if path:sub(1, 1) == '@' then
        resource, file = path:match('^@([^/%.]+)[/%.](.+)$')
        assert(resource, ('Invalid path "%s", expected "@resource/path/to/file"'):format(path))
    end

    if extension then
        file = file:gsub('%.' .. extension .. '$', '')

        -- Without a slash the dots separate folders: shared.utils -> shared/utils
        if not file:find('/', 1, true) then
            file = file:gsub('%.', '/')
        end

        file = file .. '.' .. extension
    end

    return resource, file
end

local function read(resource, file, level)
    local source = LoadResourceFile(resource, file)

    if not source then
        error(('MSK.Require: "%s/%s" was not found (a client can only read files listed in files { ... })'):format(resource, file), level + 1)
    end

    return source
end

---Runs a Lua file once and returns (and caches) its return value.
---@param path string
---@return any
function Require.Load(path)
    local resource, file = resolve(path, 'lua')
    local id = resource .. '/' .. file

    local cached = cache[id]
    if cached ~= nil then return cached end

    if loading[id] then
        error(('MSK.Require: circular dependency on "%s"'):format(id), 2)
    end

    local chunk, compileError = load(read(resource, file, 2), ('@@%s/%s'):format(resource, file))
    if not chunk then
        error(('MSK.Require: "%s" failed to compile: %s'):format(id, compileError), 2)
    end

    loading[id] = true
    local ok, result = pcall(chunk)
    loading[id] = nil

    if not ok then
        error(('MSK.Require: "%s" raised an error: %s'):format(id, result), 2)
    end

    if result == nil then result = true end
    cache[id] = result

    return result
end

---Reads and decodes a JSON file. Not cached, so edits show up on the next call.
---@param path string
---@return any
function Require.Json(path)
    local resource, file = resolve(path, 'json')
    local ok, data = pcall(json.decode, read(resource, file, 2))

    if not ok then
        error(('MSK.Require: "%s/%s" is not valid JSON'):format(resource, file), 2)
    end

    return data
end

---The raw contents of a file. The path is taken as it is, without adding an
---extension or turning dots into folders.
---@param path string
---@return string
function Require.File(path)
    local resource, file = resolve(path, nil)
    return read(resource, file, 2)
end

---Drops a cached Lua module, so the next Load runs the file again.
---@param path string
---@return boolean dropped
function Require.Unload(path)
    local resource, file = resolve(path, 'lua')
    local id = resource .. '/' .. file
    local existed = cache[id] ~= nil

    cache[id] = nil
    return existed
end

return setmetatable(Require, {
    __call = function(_, path) return Require.Load(path) end
})
