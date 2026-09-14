--------------------------------------------------------------------------------
-- Zone creator (client, msk_core only)
--
-- Builds a zone in-game and copies the finished MSK.Zones code to the
-- clipboard. Started by the command in Config.ZoneCreator, which checks the
-- permission on the server.
--
-- Aim with the camera, a small marker shows where you point at.
--   E               place the zone (box, sphere) / add a point (poly)
--   Mouse wheel     radius (sphere), width (box), thickness (poly)
--   Shift + wheel   length (box)
--   Ctrl + wheel    height (box)
--   Arrow left/right rotate (box)
--   Backspace       remove the last point (poly)
--   Enter           finish and copy
--   X               cancel
--------------------------------------------------------------------------------
if GetCurrentResourceName() ~= 'msk_core' then
    return true
end

local KEY = {
    place = 38,        -- E
    finish = 191,      -- Enter
    undo = 194,        -- Backspace
    cancel = 73,       -- X
    wheelUp = 241,
    wheelDown = 242,
    shift = 21,
    ctrl = 36,
    left = 174,
    right = 175,
}

-- Everything the creator reads, plus weapon selection and attacks, so the
-- wheel does not switch weapons and E does not trigger world interactions.
local DISABLED = { 14, 15, 16, 17, 24, 25, 37, 38, 73, 140, 141, 142, 174, 175, 191, 194, 241, 242, 257, 263 }

local creating = false

local function number(value)
    return ('%.2f'):format(value)
end

local function vec(value)
    return ('vec3(%s, %s, %s)'):format(number(value.x), number(value.y), number(value.z))
end

local function isReady(state)
    if state.shape == 'poly' then
        return #state.points >= 3
    end
    return state.coords ~= nil
end

local function buildCode(state)
    if state.shape == 'sphere' then
        return ('MSK.Zones.Sphere({\n    coords = %s,\n    radius = %s,\n})'):format(vec(state.coords), number(state.radius))
    end

    if state.shape == 'box' then
        return ('MSK.Zones.Box({\n    coords = %s,\n    size = %s,\n    rotation = %s,\n})'):format(
            vec(state.coords), vec(state.size), number(state.rotation))
    end

    local lines = {}
    for i = 1, #state.points do
        lines[i] = '        ' .. vec(state.points[i]) .. ','
    end

    return ('MSK.Zones.Poly({\n    points = {\n%s\n    },\n    thickness = %s,\n})'):format(
        table.concat(lines, '\n'), number(state.thickness))
end

local function createPreview(state)
    if state.shape == 'sphere' then
        return MSK.Zones.Sphere({ coords = state.coords, radius = state.radius, debug = true })
    end

    if state.shape == 'box' then
        return MSK.Zones.Box({ coords = state.coords, size = state.size, rotation = state.rotation, debug = true })
    end

    return MSK.Zones.Poly({ points = state.points, thickness = state.thickness, debug = true })
end

local HELP = {
    sphere = '~y~E~s~ place   ~y~Wheel~s~ radius   ~y~Enter~s~ finish   ~y~X~s~ cancel',
    box = '~y~E~s~ place   ~y~Wheel~s~ width   ~y~Shift+Wheel~s~ length   ~y~Ctrl+Wheel~s~ height~n~~y~Arrows~s~ rotate   ~y~Enter~s~ finish   ~y~X~s~ cancel',
    poly = '~y~E~s~ add point   ~y~Backspace~s~ remove point   ~y~Wheel~s~ thickness~n~~y~Enter~s~ finish   ~y~X~s~ cancel',
}

local function drawHelp(state)
    local detail

    if state.shape == 'sphere' then
        detail = ('radius %s'):format(number(state.radius))
    elseif state.shape == 'box' then
        detail = ('size %s x %s x %s   rotation %s'):format(number(state.size.x), number(state.size.y), number(state.size.z), number(state.rotation))
    else
        detail = ('points %s   thickness %s'):format(#state.points, number(state.thickness))
    end

    SetTextFont(4)
    SetTextScale(0.36, 0.36)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(('~g~ZONE CREATOR~s~ (%s)~n~%s~n~%s'):format(state.shape, HELP[state.shape], detail))
    EndTextCommandDisplayText(0.015, 0.35)
end

local function start(shape)
    if creating then return end

    shape = (shape == 'sphere' or shape == 'poly') and shape or 'box'
    creating = true

    local state = {
        shape = shape,
        coords = nil,
        size = vector3(4.0, 4.0, 3.0),
        rotation = 0.0,
        radius = 3.0,
        points = {},
        thickness = 4.0,
    }

    local preview = nil
    local dirty = false

    -- The raycast is started in one frame and read in a later one, so this loop
    -- never waits in the middle. CameraRaycast waited a frame, and in that
    -- frame the controls were not disabled (E interacted with the world, the
    -- wheel switched weapons) and key presses got lost.
    local probe = nil
    local hit, endCoords = false, nil

    CreateThread(function()
        while creating do
            for i = 1, #DISABLED do
                DisableControlAction(0, DISABLED[i], true)
            end

            if not probe then
                probe = MSK.Request.StartCameraRaycast(1 | 16, 4, 50.0)
            end

            local done, probeHit, _, probeCoords = MSK.Request.ReadRaycast(probe)

            if done then
                probe = nil
                hit, endCoords = probeHit, probeCoords
            end

            if hit then
                DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.12, 0.12, 0.12, 0, 230, 118, 220, false, false, 2, false, nil, nil, false)
            end

            if hit and IsDisabledControlJustPressed(0, KEY.place) then
                if shape == 'poly' then
                    state.points[#state.points + 1] = endCoords
                else
                    state.coords = endCoords
                end
                dirty = true
            end

            local delta = (IsDisabledControlJustPressed(0, KEY.wheelUp) and 1)
                or (IsDisabledControlJustPressed(0, KEY.wheelDown) and -1)
                or 0

            if delta ~= 0 then
                local step = delta * 0.25

                if shape == 'sphere' then
                    state.radius = math.max(0.25, state.radius + step)
                elseif shape == 'box' then
                    local size = state.size

                    if IsDisabledControlPressed(0, KEY.shift) then
                        state.size = vector3(size.x, math.max(0.25, size.y + step), size.z)
                    elseif IsDisabledControlPressed(0, KEY.ctrl) then
                        state.size = vector3(size.x, size.y, math.max(0.25, size.z + step))
                    else
                        state.size = vector3(math.max(0.25, size.x + step), size.y, size.z)
                    end
                else
                    state.thickness = math.max(0.5, state.thickness + step)
                end

                dirty = true
            end

            if shape == 'box' then
                if IsDisabledControlJustPressed(0, KEY.left) then
                    state.rotation = (state.rotation - 5.0) % 360.0
                    dirty = true
                elseif IsDisabledControlJustPressed(0, KEY.right) then
                    state.rotation = (state.rotation + 5.0) % 360.0
                    dirty = true
                end
            end

            if shape == 'poly' and IsDisabledControlJustPressed(0, KEY.undo) and #state.points > 0 then
                table.remove(state.points)
                dirty = true
            end

            -- A poly zone with fewer than three points is only drawn as lines.
            if shape == 'poly' and #state.points > 0 and #state.points < 3 then
                for i = 1, #state.points do
                    local point = state.points[i]
                    DrawMarker(28, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.2, 0.2, 0.2, 244, 63, 94, 220, false, false, 2, false, nil, nil, false)

                    local following = state.points[i + 1]
                    if following then
                        DrawLine(point.x, point.y, point.z, following.x, following.y, following.z, 244, 63, 94, 255)
                    end
                end
            end

            if dirty then
                dirty = false

                if preview then
                    preview:Remove()
                    preview = nil
                end

                if isReady(state) then
                    preview = createPreview(state)
                end
            end

            if IsDisabledControlJustPressed(0, KEY.cancel) then
                creating = false
                MSK.Notification({ title = 'Zone Creator', message = 'Cancelled.', type = 'info' })
            elseif IsDisabledControlJustPressed(0, KEY.finish) then
                if isReady(state) then
                    local code = buildCode(state)

                    MSK.Clipboard.Set(code)
                    print(code)
                    MSK.Notification({ title = 'Zone Creator', message = 'The zone code was copied to your clipboard.', type = 'success' })

                    creating = false
                else
                    MSK.Notification({
                        id = 'zone_creator_hint',
                        title = 'Zone Creator',
                        message = shape == 'poly' and 'A poly zone needs at least 3 points.' or 'Place the zone with E first.',
                        type = 'error',
                    })
                end
            end

            if creating then drawHelp(state) end

            Wait(0)
        end

        if preview then
            preview:Remove()
        end
    end)
end

RegisterNetEvent('msk_core:zoneCreator', start)

return true
