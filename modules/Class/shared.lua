--------------------------------------------------------------------------------
-- MSK.Class
--
-- A small class system. A class is a plain table that doubles as the metatable
-- of its instances, so a method lookup costs one __index hop per inheritance
-- level and nothing is copied when an instance is created.
--
--   local Vehicle = MSK.Class.New('Vehicle')
--
--   function Vehicle:init(model)
--       self.model = model
--   end
--
--   local Car = Vehicle:Extend('Car')
--
--   function Car:init(model, doors)
--       Car.Parent.init(self, model)
--       self.doors = doors
--   end
--
--   local car = Car:New('sultan', 4)   -- or: Car('sultan', 4)
--   car:IsA(Vehicle)                   -- true
--
-- Call the parent through the class name (Car.Parent), never through
-- self.Parent: self always resolves to the most derived class, so with three
-- levels self.Parent.init would call itself until the stack overflows.
--
-- FiveM exports only carry plain data. An instance handed through an export
-- arrives without its metatable and therefore without its methods, so keep
-- instances inside the resource that created them.
--------------------------------------------------------------------------------
local Class = {}

-- Metamethods are read from the metatable itself and never through __index, so
-- a child class needs its own copy of the ones the parent defines.
local INHERITED_METAMETHODS = {
    '__tostring', '__eq', '__lt', '__le', '__add', '__sub', '__mul', '__div',
    '__mod', '__unm', '__concat', '__len', '__call', '__close',
}

-- The generated __tostring of each class. Not copied to children, otherwise a
-- child instance would print the name of its parent.
local generatedToString = setmetatable({}, { __mode = 'k' })

-- Methods every class reaches at the end of its lookup chain.
local Base = {}

local function isClass(value)
    return type(value) == 'table' and rawget(value, '__class') == true
end

local function construct(cls, ...)
    local instance = setmetatable({}, cls)
    local init = cls.init

    -- init may return false to refuse the construction, e.g. on invalid input.
    if init and init(instance, ...) == false then
        return nil
    end

    return instance
end

local function define(name, parent)
    assert(type(name) == 'string' and name ~= '', 'Parameter "name" has to be a non-empty string on function MSK.Class.New')
    assert(parent == nil or isClass(parent), 'Parameter "parent" has to be a class on function MSK.Class.New')

    local cls = {
        __class = true,
        Name = name,
        Parent = parent,
    }
    cls.__index = cls

    if parent then
        for i = 1, #INHERITED_METAMETHODS do
            local key = INHERITED_METAMETHODS[i]
            local value = rawget(parent, key)

            if value ~= nil and not generatedToString[value] then
                cls[key] = value
            end
        end
    end

    if rawget(cls, '__tostring') == nil then
        local toString = function() return ('%s instance'):format(name) end
        generatedToString[toString] = true
        cls.__tostring = toString
    end

    return setmetatable(cls, {
        __index = parent or Base,
        __call = construct,
        __tostring = function() return ('class %s'):format(name) end,
    })
end

---Creates an instance. Same as calling the class directly.
function Base:New(...)
    assert(isClass(self), 'New has to be called on a class, not on an instance')
    return construct(self, ...)
end

---Creates a child class that inherits every method of this one.
---@param name string
function Base:Extend(name)
    assert(isClass(self), 'Extend has to be called on a class, not on an instance')
    return define(name, self)
end

---True when this instance or class is `cls` or inherits from it.
---@param cls table
---@return boolean
function Base:IsA(cls)
    local current = isClass(self) and self or getmetatable(self)

    while current do
        if current == cls then return true end
        current = rawget(current, 'Parent')
    end

    return false
end

---Creates a new class, optionally inheriting from `parent`.
---@param name string
---@param parent? table
---@return table
function Class.New(name, parent)
    return define(name, parent)
end

---@param value any
---@return boolean
function Class.IsClass(value)
    return isClass(value)
end

---True when `value` is an instance (not a class) of `cls` or of a child of it.
---@param value any
---@param cls table
---@return boolean
function Class.IsInstance(value, cls)
    if type(value) ~= 'table' or isClass(value) then return false end
    if not isClass(getmetatable(value)) then return false end
    return Base.IsA(value, cls)
end

return setmetatable(Class, {
    __call = function(_, name, parent) return define(name, parent) end
})
