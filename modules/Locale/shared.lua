--------------------------------------------------------------------------------
-- MSK.Locale
--
-- Translations from JSON files in the resource that uses them:
--
--   my_script/locales/en.json   { "shop": { "bought": "You bought ${item} for $%s" } }
--   my_script/locales/de.json   { "shop": { "bought": "Du hast ${item} für $%s gekauft" } }
--
--   MSK.Locale('shop.bought', { item = 'Bread' })     -- named placeholders
--   MSK.Locale.T('shop.bought', 25)                    -- string.format arguments
--
-- Nested objects become dotted keys. `${name}` is replaced from the table
-- argument; when the table has no such field, `${other.key}` pulls in another
-- translation, so repeated words live in one place.
--
-- The language is chosen in this order:
--   1. MSK.Locale.SetLanguage(...) in the resource itself
--   2. the player's own choice in the msk_core settings (client only)
--   3. the convar msk:locale  (setr msk:locale "de")
--   4. 'en'
-- Keys missing in the chosen language fall back to en.json.
--
-- On the client the JSON files have to be listed in the resource's
-- fxmanifest, e.g. files { 'locales/*.json' }.
--------------------------------------------------------------------------------
local Locale = {}

local RESOURCE = GetCurrentResourceName()
local FALLBACK = 'en'
local IS_SERVER = IsDuplicityVersion()

local strings = {}
local language = nil
local loaded = false
local override = nil
local warned = {}

local function flatten(source, prefix, into)
    for key, value in pairs(source) do
        local path = prefix and (prefix .. '.' .. tostring(key)) or tostring(key)

        if type(value) == 'table' then
            flatten(value, path, into)
        else
            into[path] = value
        end
    end
    return into
end

local function readLanguage(resource, lang)
    local raw = LoadResourceFile(resource, ('locales/%s.json'):format(lang))
    if not raw then return nil end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        print(('[^3%s^7] ^3MSK.Locale: locales/%s.json of %s is not valid JSON^7'):format(RESOURCE, lang, resource))
        return nil
    end

    return flatten(data, nil, {})
end

-- Translations of the fallback language with the chosen language on top.
local function readMerged(resource, lang)
    local merged = {}

    if lang ~= FALLBACK then
        local fallback = readLanguage(resource, FALLBACK)
        if fallback then
            for key, value in pairs(fallback) do merged[key] = value end
        end
    end

    local main = readLanguage(resource, lang)
    if main then
        for key, value in pairs(main) do merged[key] = value end
    end

    return merged, main ~= nil
end

local function playerSetting()
    if IS_SERVER or GetResourceState('msk_core') ~= 'started' then return nil end

    local ok, value = pcall(function()
        return exports.msk_core:GetSetting('locale')
    end)

    if ok and type(value) == 'string' and value ~= '' then
        return value
    end
end

local function resolveLanguage()
    if override then return override end

    local fromSetting = playerSetting()
    if fromSetting then return fromSetting end

    local fromConvar = GetConvar('msk:locale', '')
    if fromConvar ~= '' then return fromConvar end

    return FALLBACK
end

-- `source` is the table `${other.key}` references are looked up in.
local function interpolate(text, named, depth, source)
    return (text:gsub('%${([%w_%.%-]+)}', function(name)
        if named and named[name] ~= nil then
            return tostring(named[name])
        end

        local reference = source[name]
        if reference ~= nil and depth < 5 then
            return interpolate(tostring(reference), named, depth + 1, source)
        end

        -- nil keeps the placeholder as it is, which makes a typo visible.
        return nil
    end))
end

local function render(text, source, ...)
    text = tostring(text)

    local count = select('#', ...)
    local first = ...
    local named = count == 1 and type(first) == 'table' and first or nil

    text = interpolate(text, named, 0, source)

    if not named and count > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then text = formatted end
    end

    return text
end

---(Re)loads the translations. Without `lang` the language is resolved again.
---@param lang? string
---@return boolean found whether a file for the language exists
function Locale.Load(lang)
    lang = lang or resolveLanguage()

    local merged, found = readMerged(RESOURCE, lang)

    if not found then
        print(('[^3%s^7] ^3MSK.Locale: no locales/%s.json found%s^7'):format(
            RESOURCE, lang, lang ~= FALLBACK and (', using ' .. FALLBACK) or ''))
    end

    strings = merged
    language = found and lang or FALLBACK
    loaded = true
    warned = {}

    return found
end

local function ensureLoaded()
    if not loaded then Locale.Load() end
end

---The translation for `key`. A table as the only extra argument fills `${name}`
---placeholders, any other arguments go through string.format. A missing key
---returns the key itself.
---@param key string
---@param ... any
---@return string
function Locale.T(key, ...)
    ensureLoaded()

    local text = strings[key]
    if text == nil then
        if not warned[key] then
            warned[key] = true
            print(('[^3%s^7] ^3MSK.Locale: missing translation "%s" (%s)^7'):format(RESOURCE, key, language))
        end
        return key
    end

    return render(text, strings, ...)
end

-- Translations of other resources, per resource, in the language resolved here.
local foreign = {}

---A translation from the locales folder of another resource, for scripts that
---show texts of another one. Same arguments as MSK.Locale.T. The language is
---the one this resource resolves to. A missing key returns the key itself.
---On the client the other resource has to list its locale files in its
---fxmanifest, which it needs anyway.
---@param resource string
---@param key string
---@param ... any
---@return string
function Locale.GetFrom(resource, key, ...)
    assert(type(resource) == 'string', 'Parameter "resource" has to be a string on function MSK.Locale.GetFrom')

    if resource == RESOURCE then
        return Locale.T(key, ...)
    end

    ensureLoaded()

    local cached = foreign[resource]

    if not cached or cached.language ~= language then
        cached = { language = language, strings = (readMerged(resource, language)) }
        foreign[resource] = cached
    end

    local text = cached.strings[key]
    if text == nil then return key end

    return render(text, cached.strings, ...)
end

---Forces a language for this resource. nil returns to automatic resolution.
---@param lang? string
function Locale.SetLanguage(lang)
    assert(lang == nil or type(lang) == 'string', 'Parameter "lang" has to be a string on function MSK.Locale.SetLanguage')
    override = lang
    Locale.Load()
end

---@return string
function Locale.GetLanguage()
    ensureLoaded()
    return language
end

---@param key string
---@return boolean
function Locale.Has(key)
    ensureLoaded()
    return strings[key] ~= nil
end

---Copy of all translations of the active language, keyed by dotted path.
---@return table<string, string>
function Locale.GetAll()
    ensureLoaded()

    local copy = {}
    for key, value in pairs(strings) do copy[key] = value end
    return copy
end

if not IS_SERVER then
    -- The player picked another language in the msk_core settings.
    AddEventHandler('msk_core:settingChanged', function(key)
        if key == 'locale' and loaded and not override then
            Locale.Load()
            foreign = {}
        end
    end)
end

return setmetatable(Locale, {
    __call = function(_, key, ...) return Locale.T(key, ...) end
})
