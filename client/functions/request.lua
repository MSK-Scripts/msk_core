MSK.Request = {}

MSK.Request.Streaming = function(request, hasLoaded, assetType, asset, timeout, ...)
    if hasLoaded(asset) then return asset end
    request(asset, ...)

    MSK.Logging('info', ("Loading %s '%s' - remember to release it when done."):format(assetType, asset))

    return MSK.Timeout.Await(timeout or 5000, function()
        if hasLoaded(asset) then return asset end
    end, ("failed to load %s '%s' - this is likely caused by unreleased assets"):format(assetType, asset))
end
exports('RequestStreaming', MSK.Request.Streaming)

setmetatable(MSK.Request, {
    __call = function(self, ...)
        return self.Streaming(...)
    end
})

MSK.Request.ScaleformMovie = function(scaleformName, timeout)
    assert(scaleformName and type(scaleformName) == 'string', ("Parameter 'scaleformName' has to be a 'string' (reveived %s)"):format(type(scaleformName)))

    local scaleform = RequestScaleformMovie(scaleformName)

    return MSK.Timeout.Await(timeout or 5000, function()
        if HasScaleformMovieLoaded(asset) then return scaleform end
    end, ("failed to load scaleformMovie '%s'"):format(scaleformName))
end
exports('RequestScaleformMovie', MSK.Request.ScaleformMovie)

MSK.Request.AnimDict = function(animDict)
    assert(animDict and type(animDict) == 'string', ("Parameter 'animDict' has to be a 'string' (reveived %s)"):format(type(animDict)))
    assert(DoesAnimDictExist(animDict), ("attempted to load invalid animDict '%s'"):format(animDict))

    if HasAnimDictLoaded(animDict) then return animDict end

    return MSK.Request.Streaming(RequestAnimDict, HasAnimDictLoaded, 'animDict', animDict)
end
MSK.LoadAnimDict = MSK.Request.AnimDict -- Backwards compatibility
exports('RequestAnimDict', MSK.Request.AnimDict)

MSK.Request.Model = function(model)
    assert(model, 'Parameter "model" is nil')
    if type(model) ~= 'number' then model = joaat(model) end
    assert(IsModelValid(model) and IsModelInCdimage(model), ("attempted to load invalid model '%s'"):format(model))

    if HasModelLoaded(model) then return model end

    return MSK.Request.Streaming(RequestModel, HasModelLoaded, 'model', model)
end
MSK.LoadModel = MSK.Request.Model -- Backwards compatibility
exports('RequestModel', MSK.Request.Model)

MSK.Request.AnimSet = function(animSet)
    assert(animSet and type(animSet) == 'string', ("Parameter 'animSet' has to be a 'string' (reveived %s)"):format(type(animSet)))
    if HasAnimSetLoaded(animSet) then return animSet end

    return MSK.Request.Streaming(RequestAnimSet, HasAnimSetLoaded, 'animSet', animSet)
end
exports('RequestAnimSet', MSK.Request.AnimSet)

MSK.Request.PtfxAsset = function(ptFxName)
    assert(ptFxName and type(ptFxName) == 'string', ("Parameter 'ptFxName' has to be a 'string' (reveived %s)"):format(type(ptFxName)))

    if HasNamedPtfxAssetLoaded(ptFxName) then return ptFxName end

    return MSK.Request.Streaming(RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, 'ptFxName', ptFxName)
end
exports('RequestPtfxAsset', MSK.Request.PtfxAsset)

MSK.Request.TextureDict = function(textureDict)
    assert(textureDict and type(textureDict) == 'string', ("Parameter 'textureDict' has to be a 'string' (reveived %s)"):format(type(textureDict)))

    if HasStreamedTextureDictLoaded(textureDict) then return textureDict end

    return MSK.Request.Streaming(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, 'textureDict', textureDict)
end
exports('RequestTextureDict', MSK.Request.TextureDict)

MSK.Request.Raycast = function(distance, flag)
    local flags = {
        none = 0,
        all = -1,
        world = 1,
        vehicle = 2,
        ped = 4,
        object = 16,
        water = 32,
        glass = 64,
        river = 128,
        foliage = 256,
    }

    if type(flag) ~= 'number' then
        flag = flags[flag] or -1
    end

    local destination = GetOffsetFromEntityInWorldCoords(MSK.Player.ped, 0.0, distance or 5.0, 0.0)
    local handle = StartShapeTestCapsule(MSK.Player.coords, destination, distance or 5.0, flag or -1, MSK.Player.ped, 4)

    local entity = MSK.Timeout.Await(1000, function()
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)

        if retval ~= 1 and hit then
            return entityHit ~= 0 and entityHit
        end
    end, ("Function 'MSK.Request.Raycast' timed out after 1s - no result received from GetShapeTestResult (%s) on function MSK.Request.Raycast"):format(handle))

    return entity
end
exports('RequestRaycast', MSK.Request.Raycast)