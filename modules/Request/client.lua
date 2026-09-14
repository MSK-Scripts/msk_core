local Request = {}

-- Milliseconds a loader waits by default. Large addon models and texture
-- dictionaries on a busy client easily need more than the 5 seconds used before.
local DEFAULT_TIMEOUT = 30000

---Generic streaming request: loads `asset`, waits until `hasLoaded(asset)` is true.
function Request.Streaming(request, hasLoaded, assetType, asset, timeout, ...)
    if hasLoaded(asset) then return asset end
    request(asset, ...)

    MSK.Logging('info', ("Loading %s '%s' - remember to release it when done."):format(assetType, asset))

    return MSK.Timeout.Await(timeout or DEFAULT_TIMEOUT, function()
        if hasLoaded(asset) then return asset end
    end, ("failed to load %s '%s' - this is likely caused by unreleased assets"):format(assetType, asset))
end

---@param scaleformName string
---@param timeout? number milliseconds, default 30000
function Request.ScaleformMovie(scaleformName, timeout)
    assert(scaleformName and type(scaleformName) == 'string', ("Parameter 'scaleformName' has to be a 'string' (reveived %s)"):format(type(scaleformName)))

    local scaleform = RequestScaleformMovie(scaleformName)

    return MSK.Timeout.Await(timeout or DEFAULT_TIMEOUT, function()
        if HasScaleformMovieLoaded(scaleform) then return scaleform end
    end, ("failed to load scaleformMovie '%s'"):format(scaleformName))
end

---@param animDict string
---@param timeout? number milliseconds, default 30000
function Request.AnimDict(animDict, timeout)
    assert(animDict and type(animDict) == 'string', ("Parameter 'animDict' has to be a 'string' (reveived %s)"):format(type(animDict)))
    assert(DoesAnimDictExist(animDict), ("attempted to load invalid animDict '%s'"):format(animDict))

    if HasAnimDictLoaded(animDict) then return animDict end

    return Request.Streaming(RequestAnimDict, HasAnimDictLoaded, 'animDict', animDict, timeout)
end

---@param model string|number
---@param timeout? number milliseconds, default 30000
function Request.Model(model, timeout)
    assert(model, 'Parameter "model" is nil')
    if type(model) ~= 'number' then model = joaat(model) end
    assert(IsModelValid(model) and IsModelInCdimage(model), ("attempted to load invalid model '%s'"):format(model))

    if HasModelLoaded(model) then return model end

    return Request.Streaming(RequestModel, HasModelLoaded, 'model', model, timeout)
end

---@param animSet string
---@param timeout? number milliseconds, default 30000
function Request.AnimSet(animSet, timeout)
    assert(animSet and type(animSet) == 'string', ("Parameter 'animSet' has to be a 'string' (reveived %s)"):format(type(animSet)))
    if HasAnimSetLoaded(animSet) then return animSet end

    return Request.Streaming(RequestAnimSet, HasAnimSetLoaded, 'animSet', animSet, timeout)
end

---@param ptFxName string
---@param timeout? number milliseconds, default 30000
function Request.PtfxAsset(ptFxName, timeout)
    assert(ptFxName and type(ptFxName) == 'string', ("Parameter 'ptFxName' has to be a 'string' (reveived %s)"):format(type(ptFxName)))

    if HasNamedPtfxAssetLoaded(ptFxName) then return ptFxName end

    return Request.Streaming(RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, 'ptFxName', ptFxName, timeout)
end

---@param textureDict string
---@param timeout? number milliseconds, default 30000
function Request.TextureDict(textureDict, timeout)
    assert(textureDict and type(textureDict) == 'string', ("Parameter 'textureDict' has to be a 'string' (reveived %s)"):format(type(textureDict)))

    if HasStreamedTextureDictLoaded(textureDict) then return textureDict end

    return Request.Streaming(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, 'textureDict', textureDict, timeout)
end

function Request.Raycast(distance, flag)
    local flags = {
        none = 0, all = -1, world = 1, vehicle = 2, ped = 4,
        object = 16, water = 32, glass = 64, river = 128, foliage = 256,
    }

    if type(flag) ~= 'number' then
        flag = flags[flag] or -1
    end

    distance = distance or 5.0

    local origin = MSK.Player.coords
    local destination = GetOffsetFromEntityInWorldCoords(MSK.Player.ped, 0.0, distance, 0.0)

    -- A line. The capsule before used the distance as its radius, a 5 m wide
    -- tube that hit things far off to the side.
    local handle = StartShapeTestLosProbe(
        origin.x, origin.y, origin.z,
        destination.x, destination.y, destination.z,
        flag or -1, MSK.Player.ped, 4
    )

    local deadline = GetGameTimer() + 1000

    while GetGameTimer() < deadline do
        local status, hit, _, _, entityHit = GetShapeTestResult(handle)

        -- 1 means still running. A miss is a result too: it used to be ignored
        -- until the wait ran out and raised an error, so aiming at empty space
        -- was enough to end the calling thread.
        if status ~= 1 then
            if status == 2 and (hit == true or hit == 1) and entityHit ~= 0 then
                return entityHit
            end

            return false
        end

        Wait(0)
    end

    return false
end

---Loads a script audio bank. RequestScriptAudioBank has to be called until it
---reports success, so this keeps asking until then or until `timeout`.
---@param audioBank string
---@param timeout? number default 30000
---@return string
function Request.AudioBank(audioBank, timeout)
    assert(audioBank and type(audioBank) == 'string', ("Parameter 'audioBank' has to be a 'string' (reveived %s)"):format(type(audioBank)))

    return MSK.Timeout.Await(timeout or 30000, function()
        if RequestScriptAudioBank(audioBank, false) then return audioBank end
    end, ("failed to load audioBank '%s'"):format(audioBank))
end

---Loads the assets of a weapon (model and animations), e.g. before giving a
---ped a weapon it never had.
---@param weapon string|number
---@param flags? number default 31 (everything)
---@param extraComponents? number
---@param timeout? number milliseconds, default 30000
---@return number weaponHash
function Request.WeaponAsset(weapon, flags, extraComponents, timeout)
    assert(weapon, 'Parameter "weapon" is nil')
    if type(weapon) ~= 'number' then weapon = joaat(weapon) end

    if HasWeaponAssetLoaded(weapon) then return weapon end

    return Request.Streaming(RequestWeaponAsset, HasWeaponAssetLoaded, 'weaponAsset', weapon, timeout, flags or 31, extraComponents or 0)
end

-- Waits up to a second for a started raycast.
local function awaitRaycast(handle, destination)
    local deadline = GetGameTimer() + 1000

    while GetGameTimer() < deadline do
        local done, hit, entityHit, endCoords, surfaceNormal, material = Request.ReadRaycast(handle)

        if done then
            return hit, entityHit, endCoords, surfaceNormal, material
        end

        Wait(0)
    end

    return false, 0, destination, vector3(0.0, 0.0, 0.0), 0
end

---Casts a ray from the camera in the direction it looks.
---@param flags? number shape test flags, default 511 (everything)
---@param ignore? number default 4
---@param distance? number default 10.0
---@return boolean hit, number entityHit, vector3 endCoords, vector3 surfaceNormal, number materialHash
function Request.CameraRaycast(flags, ignore, distance)
    local handle, destination = Request.StartCameraRaycast(flags, ignore, distance)
    return awaitRaycast(handle, destination)
end

---Casts a ray between two points and waits for the result (at most a second).
---@param from vector3
---@param to vector3
---@param flags? number shape test flags, default 511 (everything)
---@param ignore? number default 4
---@param ignoreEntity? number entity the ray passes through, default the player's ped
---@return boolean hit, number entityHit, vector3 endCoords, vector3 surfaceNormal, number materialHash
function Request.RaycastFromCoords(from, to, flags, ignore, ignoreEntity)
    assert(from and from.x and to and to.x, 'Parameters "from" and "to" have to be vectors on function MSK.Request.RaycastFromCoords')

    local handle = StartShapeTestLosProbe(
        from.x, from.y, from.z,
        to.x, to.y, to.z,
        flags or 511, ignoreEntity or MSK.Player.ped, ignore or 4
    )

    return awaitRaycast(handle, to)
end

---Starts a camera raycast without waiting for it. For code that runs every
---frame and must not yield (a Wait inside such a loop skips input and control
---handling for that frame). Read the result with Request.ReadRaycast.
---@param flags? number default 511
---@param ignore? number default 4
---@param distance? number default 10.0
---@return number handle, vector3 destination
function Request.StartCameraRaycast(flags, ignore, distance)
    distance = distance or 10.0

    local camCoords = GetFinalRenderedCamCoord()
    local camRotation = GetFinalRenderedCamRot(2)

    local pitch, yaw = math.rad(camRotation.x), math.rad(camRotation.z)
    local horizontal = math.abs(math.cos(pitch))
    local direction = vector3(-math.sin(yaw) * horizontal, math.cos(yaw) * horizontal, math.sin(pitch))
    local destination = camCoords + direction * distance

    local handle = StartShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        flags or 511, MSK.Player.ped, ignore or 4
    )

    return handle, destination
end

---Result of a raycast started with Request.StartCameraRaycast.
---@param handle number
---@return boolean done, boolean hit, number entityHit, vector3 endCoords, vector3 surfaceNormal, number materialHash
function Request.ReadRaycast(handle)
    local status, hit, endCoords, surfaceNormal, material, entityHit = GetShapeTestResultIncludingMaterial(handle)

    -- 1 means the test is still running.
    if status == 1 then return false end

    return true, status == 2 and (hit == true or hit == 1), entityHit, endCoords, surfaceNormal, material
end

return setmetatable(Request, {
    __call = function(self, ...)
        return self.Streaming(...)
    end
})
