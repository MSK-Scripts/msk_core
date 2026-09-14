--------------------------------------------------------------------------------
-- MSK.VehicleProperties (client)
--
-- Reads and applies the full visual and damage state of a vehicle.
--
--   local props = MSK.VehicleProperties.Get(vehicle)
--   MSK.VehicleProperties.Set(vehicle, props)
--
-- The field names follow the format that ox_lib and QBCore/Qbox store in
-- player_vehicles, so rows written by other garages load here and rows written
-- here load there. The legacy QBCore names modKit17/19/21/47/49 are accepted
-- when applying.
--
-- Colors are an index (number) or a custom color { r, g, b }. extras use the
-- stored convention 0 = on, 1 = off. windows and doors list the broken ones,
-- tyres map a wheel index to 1 (burst) or 2 (on the rim).
--
-- Set only takes effect on the client that owns the vehicle. From the server
-- use MSK.VehicleProperties.Set there, which routes to the owner.
--------------------------------------------------------------------------------
local IS_CORE = GetCurrentResourceName() == 'msk_core'
local Props = {}

local MODS = {
    modSpoilers = 0, modFrontBumper = 1, modRearBumper = 2, modSideSkirt = 3,
    modExhaust = 4, modFrame = 5, modGrille = 6, modHood = 7, modFender = 8,
    modRightFender = 9, modRoof = 10, modEngine = 11, modBrakes = 12,
    modTransmission = 13, modHorns = 14, modSuspension = 15, modArmor = 16,
    modNitrous = 17, modSubwoofer = 19, modHydraulics = 21,
    modPlateHolder = 25, modVanityPlate = 26, modTrimA = 27, modOrnaments = 28,
    modDashboard = 29, modDial = 30, modDoorSpeaker = 31, modSeats = 32,
    modSteeringWheel = 33, modShifterLeavers = 34, modAPlate = 35,
    modSpeakers = 36, modTrunk = 37, modHydrolic = 38, modEngineBlock = 39,
    modAirFilter = 40, modStruts = 41, modArchCover = 42, modAerials = 43,
    modTrimB = 44, modTank = 45, modWindows = 46, modDoorR = 47,
    modLivery = 48, modLightbar = 49,
}

local TOGGLE_MODS = { modTurbo = 18, modSmokeEnabled = 20, modXenon = 22 }

local LEGACY_NAMES = {
    modKit17 = 'modNitrous',
    modKit19 = 'modSubwoofer',
    modKit21 = 'modHydraulics',
    modKit47 = 'modDoorR',
    modKit49 = 'modLightbar',
}

local TYRES = { 0, 1, 2, 3, 4, 5, 45, 47 }

-- Drift tyres exist from game build 2372 on, the natives fail on older builds.
local SUPPORTS_DRIFT_TYRES = GetGameBuildNumber() >= 2372

local function readDriftTyres(vehicle)
    if not SUPPORTS_DRIFT_TYRES then return nil end
    return GetDriftTyresEnabled(vehicle)
end

local function round(value, decimals)
    local factor = 10 ^ (decimals or 1)
    return math.floor(value * factor + 0.5) / factor
end

local function rgb(r, g, b)
    return { r, g, b }
end

local function readRgb(color)
    if type(color) ~= 'table' then return nil end
    return color.r or color[1] or 0, color.g or color[2] or 0, color.b or color[3] or 0
end

---The properties of `vehicle`, or nil when it does not exist.
---@param vehicle number
---@return table?
function Props.Get(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return nil end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local paintType1 = GetVehicleModColor_1(vehicle)
    local paintType2 = GetVehicleModColor_2(vehicle)

    if GetIsVehiclePrimaryColourCustom(vehicle) then
        colorPrimary = rgb(GetVehicleCustomPrimaryColour(vehicle))
    end

    if GetIsVehicleSecondaryColourCustom(vehicle) then
        colorSecondary = rgb(GetVehicleCustomSecondaryColour(vehicle))
    end

    local props = {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth = round(GetVehicleBodyHealth(vehicle)),
        engineHealth = round(GetVehicleEngineHealth(vehicle)),
        tankHealth = round(GetVehiclePetrolTankHealth(vehicle)),
        fuelLevel = round(GetVehicleFuelLevel(vehicle)),
        oilLevel = round(GetVehicleOilLevel(vehicle)),
        dirtLevel = round(GetVehicleDirtLevel(vehicle)),

        paintType1 = paintType1,
        paintType2 = paintType2,
        color1 = colorPrimary,
        color2 = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        interiorColor = GetVehicleInteriorColour(vehicle),
        dashboardColor = GetVehicleDashboardColour(vehicle),

        wheels = GetVehicleWheelType(vehicle),
        wheelWidth = round(GetVehicleWheelWidth(vehicle), 3),
        wheelSize = round(GetVehicleWheelSize(vehicle), 3),
        windowTint = GetVehicleWindowTint(vehicle),

        neonEnabled = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3),
        },
        neonColor = rgb(GetVehicleNeonLightsColour(vehicle)),
        tyreSmokeColor = rgb(GetVehicleTyreSmokeColor(vehicle)),

        modFrontWheels = GetVehicleMod(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),
        modCustomTiresF = GetVehicleModVariation(vehicle, 23),
        modCustomTiresR = GetVehicleModVariation(vehicle, 24),

        livery = GetVehicleLivery(vehicle),
        roofLivery = GetVehicleRoofLivery(vehicle),

        -- Despite the name this is "tyres can burst", stored raw. That is how
        -- ox_lib writes the field, and rows have to mean the same in both.
        bulletProofTyres = GetVehicleTyresCanBurst(vehicle),
        driftTyres = readDriftTyres(vehicle),

        extras = {},
        windows = {},
        doors = {},
        tyres = {},
    }

    local hasCustomXenon, xenonR, xenonG, xenonB = GetVehicleXenonLightsCustomColor(vehicle)
    if hasCustomXenon then
        props.xenonColor = { xenonR, xenonG, xenonB }
    else
        props.xenonColor = GetVehicleXenonLightsColor(vehicle)
    end

    for name, modType in pairs(MODS) do
        props[name] = GetVehicleMod(vehicle, modType)
    end

    for name, modType in pairs(TOGGLE_MODS) do
        props[name] = IsToggleModOn(vehicle, modType)
    end

    for id = 0, 20 do
        if DoesExtraExist(vehicle, id) then
            props.extras[tostring(id)] = IsVehicleExtraTurnedOn(vehicle, id) and 0 or 1
        end
    end

    for id = 0, 7 do
        if not IsVehicleWindowIntact(vehicle, id) then
            props.windows[#props.windows + 1] = id
        end
    end

    for id = 0, 5 do
        if IsVehicleDoorDamaged(vehicle, id) then
            props.doors[#props.doors + 1] = id
        end
    end

    for i = 1, #TYRES do
        local id = TYRES[i]

        if IsVehicleTyreBurst(vehicle, id, false) then
            props.tyres[tostring(id)] = IsVehicleTyreBurst(vehicle, id, true) and 2 or 1
        end
    end

    return props
end

---Applies `props` to `vehicle`. Fields that are nil are left untouched. With
---`fixVehicle` the vehicle is repaired first and the stored damage is skipped.
---@param vehicle number
---@param props table
---@param fixVehicle? boolean
---@return boolean applied
function Props.Set(vehicle, props, fixVehicle)
    if not vehicle or not DoesEntityExist(vehicle) or type(props) ~= 'table' then return false end

    -- Never change the caller's table, it may be reused or stored.
    local p = {}
    for key, value in pairs(props) do p[key] = value end

    for legacy, current in pairs(LEGACY_NAMES) do
        if p[current] == nil and p[legacy] ~= nil then
            p[current] = p[legacy]
        end
    end

    SetVehicleModKit(vehicle, 0)

    if fixVehicle then
        SetVehicleFixed(vehicle)
    end

    if p.plate then SetVehicleNumberPlateText(vehicle, p.plate) end
    if p.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, p.plateIndex) end

    if p.bodyHealth then SetVehicleBodyHealth(vehicle, p.bodyHealth + 0.0) end
    if p.engineHealth then SetVehicleEngineHealth(vehicle, p.engineHealth + 0.0) end
    if p.tankHealth then SetVehiclePetrolTankHealth(vehicle, p.tankHealth + 0.0) end
    if p.fuelLevel then SetVehicleFuelLevel(vehicle, p.fuelLevel + 0.0) end
    if p.oilLevel then SetVehicleOilLevel(vehicle, p.oilLevel + 0.0) end
    if p.dirtLevel then SetVehicleDirtLevel(vehicle, p.dirtLevel + 0.0) end

    -- Colors. Paint types first: SetVehicleModColor also changes the color.
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

    if p.paintType1 then SetVehicleModColor_1(vehicle, p.paintType1, 0, p.pearlescentColor or pearlescentColor) end
    if p.paintType2 then SetVehicleModColor_2(vehicle, p.paintType2, 0) end

    if p.color1 ~= nil then
        if type(p.color1) == 'number' then
            ClearVehicleCustomPrimaryColour(vehicle)
            colorPrimary = p.color1
        else
            SetVehicleCustomPrimaryColour(vehicle, readRgb(p.color1))
        end
    end

    if p.color2 ~= nil then
        if type(p.color2) == 'number' then
            ClearVehicleCustomSecondaryColour(vehicle)
            colorSecondary = p.color2
        else
            SetVehicleCustomSecondaryColour(vehicle, readRgb(p.color2))
        end
    end

    SetVehicleColours(vehicle, colorPrimary, colorSecondary)

    if p.pearlescentColor or p.wheelColor then
        SetVehicleExtraColours(vehicle, p.pearlescentColor or pearlescentColor, p.wheelColor or wheelColor)
    end

    if p.interiorColor then SetVehicleInteriorColour(vehicle, p.interiorColor) end
    if p.dashboardColor then SetVehicleDashboardColour(vehicle, p.dashboardColor) end

    -- The wheel type decides which wheel mods exist, so it comes before them.
    if p.wheels then SetVehicleWheelType(vehicle, p.wheels) end
    if p.windowTint then SetVehicleWindowTint(vehicle, p.windowTint) end

    if p.neonEnabled then
        for i = 1, 4 do
            SetVehicleNeonLightEnabled(vehicle, i - 1, p.neonEnabled[i] == true or p.neonEnabled[i] == 1)
        end
    end

    if p.neonColor then SetVehicleNeonLightsColour(vehicle, readRgb(p.neonColor)) end
    if p.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, readRgb(p.tyreSmokeColor)) end

    for name, modType in pairs(MODS) do
        if p[name] ~= nil then
            SetVehicleMod(vehicle, modType, p[name], false)
        end
    end

    for name, modType in pairs(TOGGLE_MODS) do
        if p[name] ~= nil then
            ToggleVehicleMod(vehicle, modType, p[name] == true or p[name] == 1)
        end
    end

    if p.modFrontWheels then SetVehicleMod(vehicle, 23, p.modFrontWheels, p.modCustomTiresF == true or p.modCustomTiresF == 1) end
    if p.modBackWheels then SetVehicleMod(vehicle, 24, p.modBackWheels, p.modCustomTiresR == true or p.modCustomTiresR == 1) end

    if p.wheelWidth then SetVehicleWheelWidth(vehicle, p.wheelWidth + 0.0) end
    if p.wheelSize then SetVehicleWheelSize(vehicle, p.wheelSize + 0.0) end

    if p.xenonColor ~= nil then
        if type(p.xenonColor) == 'table' then
            SetVehicleXenonLightsCustomColor(vehicle, readRgb(p.xenonColor))
        else
            ClearVehicleXenonLightsCustomColor(vehicle)
            SetVehicleXenonLightsColor(vehicle, p.xenonColor)
        end
    end

    if p.livery and p.livery >= 0 then SetVehicleLivery(vehicle, p.livery) end
    if p.roofLivery and p.roofLivery >= 0 then SetVehicleRoofLivery(vehicle, p.roofLivery) end

    -- Raw "tyres can burst", see Get.
    if p.bulletProofTyres ~= nil then SetVehicleTyresCanBurst(vehicle, p.bulletProofTyres == true or p.bulletProofTyres == 1) end
    if p.driftTyres ~= nil and SUPPORTS_DRIFT_TYRES then SetDriftTyresEnabled(vehicle, p.driftTyres == true) end

    if p.extras then
        for id, state in pairs(p.extras) do
            id = tonumber(id)

            if id and DoesExtraExist(vehicle, id) then
                -- Stored value is "disabled": 0 = on, 1 = off. A boolean means on/off.
                local disable = state == 1 or state == false
                SetVehicleExtra(vehicle, id, disable)
            end
        end
    end

    if not fixVehicle then
        if p.windows then
            for _, id in pairs(p.windows) do
                SmashVehicleWindow(vehicle, tonumber(id))
            end
        end

        if p.doors then
            for _, id in pairs(p.doors) do
                SetVehicleDoorBroken(vehicle, tonumber(id), true)
            end
        end

        if p.tyres then
            for id, state in pairs(p.tyres) do
                SetVehicleTyreBurst(vehicle, tonumber(id), state == 2, 1000.0)
            end
        end
    end

    return true
end

if IS_CORE then
    local STATE_KEY = 'msk_core:vehicleProperties'

    exports('GetVehicleProperties', Props.Get)
    exports('SetVehicleProperties', Props.Set)

    -- Server-side Set writes the properties into this state bag. Only the owner
    -- of the entity can apply them, so every client checks and the owner acts.
    AddStateBagChangeHandler(STATE_KEY, '', function(bagName, _, value)
        if type(value) ~= 'table' then return end

        local entity = GetEntityFromStateBagName(bagName)
        local deadline = GetGameTimer() + 10000

        -- The bag can arrive before the entity exists on this client.
        while entity == 0 and GetGameTimer() < deadline do
            Wait(0)
            entity = GetEntityFromStateBagName(bagName)
        end

        if entity == 0 then return end

        -- Right after spawning the owner can still change. Checking once lost
        -- the properties whenever the entity was not owned yet at that moment.
        for _ = 1, 10 do
            if not DoesEntityExist(entity) then return end

            if NetworkGetEntityOwner(entity) == PlayerId() then
                Props.Set(entity, value.props, value.fix)

                -- The server clears the bag. A client write is refused when
                -- sv_stateBagStrictMode is on, and the bag then stayed set.
                TriggerServerEvent('msk_core:vehiclePropertiesApplied', NetworkGetNetworkIdFromEntity(entity))
                return
            end

            Wait(400)
        end
    end)

    MSK.VehicleProperties = Props
end

return Props
