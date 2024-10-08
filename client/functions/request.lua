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

MSK.Request.ScaleformMovie = function(scaleformName, timeout)
    assert(scaleformName and type(scaleformName) == 'string', ("Parameter 'scaleformName' has to be a 'string' (reveived %s)"):format(type(scaleformName)))

    local scaleform = RequestScaleformMovie(scaleformName)

    return MSK.Timeout.Await(timeout or 5000, function()
        if HasScaleformMovieLoaded(asset) then return scaleform end
    end, ("failed to load scaleformMovie '%s'"):format(scaleformName))
end
exports('RequestScaleformMovie', MSK.Request.ScaleformMovie)

setmetatable(MSK.Request, {
    __call = function(_, request, hasLoaded, assetType, asset, timeout, ...)
        return MSK.Request.Streaming(request, hasLoaded, assetType, asset, timeout, ...)
    end
})

MSK.Request.AnimDict = function(animDict)
    assert(animDict and type(animDict) == 'string', ("Parameter 'animDict' has to be a 'string' (reveived %s)"):format(type(animDict)))
    assert(DoesAnimDictExist(animDict), ("attempted to load invalid animDict '%s'"):format(animDict))

    if HasAnimDictLoaded(animDict) then return animDict end

    return MSK.Request(RequestAnimDict, HasAnimDictLoaded, 'animDict', animDict)
end
MSK.LoadAnimDict = MSK.Request.AnimDict -- Support for old Versions
exports('LoadAnimDict', MSK.Request.AnimDict) -- Support for old Versions
exports('RequestAnimDict', MSK.Request.AnimDict)

MSK.Request.Model = function(model)
    assert(model, 'Parameter "model" is nil')
    if type(model) ~= 'number' then model = joaat(model) end
    assert(IsModelValid(model) and IsModelInCdimage(model), ("attempted to load invalid model '%s'"):format(model))

    if HasModelLoaded(model) then return model end

    return MSK.Request(RequestModel, HasModelLoaded, 'model', model)
end
MSK.LoadModel = MSK.Request.Model -- Support for old Versions
exports('LoadModel', MSK.Request.Model) -- Support for old Versions
exports('RequestModel', MSK.Request.Model)

MSK.Request.AnimSet = function(animSet)
    assert(animSet and type(animSet) == 'string', ("Parameter 'animSet' has to be a 'string' (reveived %s)"):format(type(animSet)))
    if HasAnimSetLoaded(animSet) then return animSet end

    return MSK.Request(RequestAnimSet, HasAnimSetLoaded, 'animSet', animSet)
end
exports('RequestAnimSet', MSK.Request.AnimSet)

MSK.Request.PtfxAsset = function(ptFxName)
    assert(ptFxName and type(ptFxName) == 'string', ("Parameter 'ptFxName' has to be a 'string' (reveived %s)"):format(type(ptFxName)))

    if HasNamedPtfxAssetLoaded(ptFxName) then return ptFxName end

    return MSK.Request(RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, 'ptFxName', ptFxName)
end
exports('RequestPtfxAsset', MSK.Request.PtfxAsset)

MSK.Request.TextureDict = function(textureDict)
    assert(textureDict and type(textureDict) == 'string', ("Parameter 'textureDict' has to be a 'string' (reveived %s)"):format(type(textureDict)))

    if HasStreamedTextureDictLoaded(textureDict) then return textureDict end

    return MSK.Request(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, 'textureDict', textureDict)
end
exports('RequestTextureDict', MSK.Request.TextureDict)