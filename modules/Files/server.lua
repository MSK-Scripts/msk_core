--------------------------------------------------------------------------------
-- MSK.Files (server)
--
-- Lists the files inside a folder of a resource. LoadResourceFile can read a
-- file but cannot tell which files exist, so data folders (one file per job,
-- per vehicle, ...) otherwise need a hand-maintained index.
--
--   for _, name in ipairs(MSK.Files.List(nil, 'data/jobs', '%.json$')) do
--       local job = MSK.Require.Json('data/jobs/' .. name)
--   end
--------------------------------------------------------------------------------
local Files = {}

local IS_WINDOWS = package.config:sub(1, 1) == '\\'

---Names of the files (not folders) directly inside `path` of `resource`,
---sorted alphabetically. `pattern` is an optional Lua pattern the name has to
---match.
---@param resource? string defaults to the calling resource
---@param path string folder relative to the resource root
---@param pattern? string
---@return string[]
function Files.List(resource, path, pattern)
    resource = resource or GetCurrentResourceName()
    assert(type(path) == 'string', 'Parameter "path" has to be a string on function MSK.Files.List')

    -- The path ends up in a shell command. Quotes and parent references are
    -- refused rather than escaped, a data folder never needs them.
    assert(not path:find('["`$]') and not path:find('%.%.'), ('Unsafe path "%s" on function MSK.Files.List'):format(path))

    local root = GetResourcePath(resource)
    assert(root and root ~= '', ('Resource "%s" was not found on function MSK.Files.List'):format(resource))

    local folder = (root .. '/' .. path):gsub('[/\\]+$', '')
    local command

    if IS_WINDOWS then
        command = ('dir "%s" /b /a-d 2>nul'):format(folder:gsub('/', '\\'))
    else
        -- ls instead of find: -printf is GNU only, and the busybox find of the
        -- Linux server does not know it, so the list was always empty. -p marks
        -- folders with a trailing slash, they are skipped below.
        command = ('ls -1Ap "%s" 2>/dev/null'):format(folder)
    end

    local handle = io.popen(command)
    if not handle then return {} end

    local result = {}
    for name in handle:lines() do
        name = name:gsub('\r$', '')

        if name ~= '' and not name:find('/$') and (not pattern or name:match(pattern)) then
            result[#result + 1] = name
        end
    end
    handle:close()

    table.sort(result)
    return result
end

return Files
