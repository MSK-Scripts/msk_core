local IS_CORE = GetCurrentResourceName() == 'msk_core'

local Callbacks = {}        -- eventName -> handler function
local CallbackHandler = {}  -- requestId -> 'request' | { result... } | nil

local function GenerateCallbackHandlerKey()
    local requestId = math.random(1, 999999999)
    return not CallbackHandler[requestId] and tostring(requestId) or GenerateCallbackHandlerKey()
end

local Callback = {}
