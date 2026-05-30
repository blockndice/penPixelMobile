-- module/animation.lua

local M = {}

-- 🎆 Explosion feu d'artifice (animation)
function M.fireWork(x, y, color, parentGroup)
    local particleCount = 12  -- Nombre de particules
    for i = 1, particleCount do
        local particle = display.newCircle(x, y, 10)
        particle:setFillColor(unpack(color))

        if parentGroup and parentGroup.insert then
            parentGroup:insert(particle)
        end

        local angle = math.random() * 2 * math.pi
        local distance = math.random(40, 80)
        local dx = math.cos(angle) * distance
        local dy = math.sin(angle) * distance

        transition.to(particle, {
            time = 400,
            x = x + dx,
            y = y + dy,
            alpha = 0,
            xScale = 0.2,
            yScale = 0.2,
            onComplete = function()
                particle:removeSelf()
            end
        })
    end
end

-- 🎯 Implosion feu d'artifice inversée (retrait de pixel)
function M.Implosion(x, y, color, parentGroup)
    local particleCount = 10
    local radius = 25  -- Distance de départ des particules

    for i = 1, particleCount do
        local angle = math.random() * 2 * math.pi
        local dx = math.cos(angle) * radius
        local dy = math.sin(angle) * radius

        local px = x + dx
        local py = y + dy

        local particle = display.newCircle(px, py, 5)
        particle:setFillColor(unpack(color))

        if parentGroup and parentGroup.insert then
            parentGroup:insert(particle)
        end

        transition.to(particle, {
            time = 400,
            x = x,
            y = y,
            alpha = 0,
            xScale = 0.1,
            yScale = 0.1,
            onComplete = function()
                particle:removeSelf()
            end
        })
    end
end

function M.ringBoom(x, y, color, parentGroup)
    local particleCount = 10
    local radius = 25  -- Distance de départ des particules

    for i = 1, particleCount do
        local angle = math.random() * 2 * math.pi
        local dx = math.cos(angle) * radius
        local dy = math.sin(angle) * radius

        local px = x + dx
        local py = y + dy

        local particle = display.newCircle(px, py, 5)
        particle:setFillColor(unpack(color))

        if parentGroup and parentGroup.insert then
            parentGroup:insert(particle)
        end

        -- 🚀 Ici, on les fait partir vers l'extérieur à partir de leur position
        local pushDistance = 30  -- distance en plus vers l'extérieur
        local tx = px + dx * (pushDistance / radius)
        local ty = py + dy * (pushDistance / radius)

        transition.to(particle, {
            time = 400,
            x = tx,
            y = ty,
            alpha = 0,
            xScale = 0.2,
            yScale = 0.2,
            transition = easing.outQuad,
            onComplete = function()
                particle:removeSelf()
            end
        })
    end
end



-- 🎊 Grand finale (victoire)
function M.grandFinale(gridOffsetX, gridOffsetY, rows, cols, cellSize, colors, colorMap, parentGroup)

    local function makeColor()
        local hue = math.random() * 6
        local x   = 1 - math.abs(hue % 2 - 1)
        local r, g, b
        if hue < 1 then r,g,b=1,x,0 elseif hue < 2 then r,g,b=x,1,0
        elseif hue < 3 then r,g,b=0,1,x elseif hue < 4 then r,g,b=0,x,1
        elseif hue < 5 then r,g,b=x,0,1 else r,g,b=1,0,x end
        return r, g, b
    end

    -- Vague de bursts colorés (x2)
    for k = 1, 56 do
        timer.performWithDelay(math.random(0, 1200), function()
            local i = math.random(1, rows)
            local j = math.random(1, cols)
            local x = gridOffsetX + (j - 1) * cellSize
            local y = gridOffsetY + (i - 1) * cellSize
            local colorIdx = math.random(1, #colors)
            local color = colorMap[colors[colorIdx]] or {1, 0.8, 0}
            M.fireWork(x, y, color, parentGroup)
        end)
    end

    -- Pluie d'étoiles en diamant (x2)
    for k = 1, 36 do
        timer.performWithDelay(math.random(0, 1400), function()
            local sz = math.random(8, 20)
            local sx = math.random(
                math.floor(gridOffsetX - cellSize),
                math.floor(gridOffsetX + (cols - 1) * cellSize + cellSize))
            local sy = gridOffsetY - math.random(20, 140)
            local star = display.newPolygon(sx, sy,
                {0,-sz, sz*0.4,-sz*0.4, sz,0, sz*0.4,sz*0.4,
                 0,sz, -sz*0.4,sz*0.4, -sz,0, -sz*0.4,-sz*0.4})
            local r, g, b = makeColor()
            star:setFillColor(r, g, b)
            star.rotation = math.random(0, 360)
            if parentGroup then parentGroup:insert(star) end
            transition.to(star, {
                time       = math.random(900, 1800),
                y          = sy + math.random(200, 420),
                rotation   = star.rotation + math.random(120, 400),
                alpha      = 0,
                xScale     = 0.1,
                yScale     = 0.1,
                transition = easing.outQuad,
                onComplete = function() display.remove(star) end,
            })
        end)
    end
end

-- 📳 Vibration buzzer (erreur)
-- Touche uniquement obj.x — n'interfère jamais avec xScale/yScale
function M.shakeText(obj, flashColor, normalColor)
    flashColor  = flashColor  or {0.92, 0.22, 0.22}
    normalColor = normalColor or {1, 1, 1}

    -- Annule un pulse en cours (remet le scale à 1)
    if obj._pulseHandle then
        transition.cancel(obj._pulseHandle)
        obj._pulseHandle = nil
        obj.xScale = 1
        obj.yScale = 1
    end

    -- Annule un shake en cours
    if obj._shakeHandle then
        transition.cancel(obj._shakeHandle)
        obj._shakeHandle = nil
    end

    local ox = obj._baseX or obj.x
    obj.x = ox

    obj:setFillColor(unpack(flashColor))
    local amps = {-9, 9, -7, 7, -5, 5, -3, 3, 0}
    local step = 0

    local function nextStep()
        step = step + 1
        if step <= #amps then
            obj._shakeHandle = transition.to(obj, {
                time       = 38,
                x          = ox + amps[step],
                transition = easing.linear,
                onComplete = nextStep,
            })
        else
            obj.x            = ox
            obj._shakeHandle = nil
            obj:setFillColor(unpack(normalColor))
        end
    end
    nextStep()
end

-- 💥 Pulse centré sur un objet texte avec flash couleur
-- Touche uniquement xScale/yScale — n'interfère jamais avec obj.x ou anchorX
function M.pulseText(obj, scaleUp, duration, flashColor, normalColor)
    scaleUp     = scaleUp    or 1.5
    duration    = duration   or 160
    flashColor  = flashColor or {1, 1, 1}
    normalColor = normalColor or {1, 1, 1}

    -- Annule un shake en cours (remet obj.x à sa base)
    if obj._shakeHandle then
        transition.cancel(obj._shakeHandle)
        obj._shakeHandle = nil
        obj.x = obj._baseX or obj.x
    end

    -- Annule un pulse en cours
    if obj._pulseHandle then
        transition.cancel(obj._pulseHandle)
        obj._pulseHandle = nil
    end
    obj.xScale = 1
    obj.yScale = 1

    obj:setFillColor(unpack(flashColor))

    obj._pulseHandle = transition.to(obj, {
        time       = duration,
        xScale     = scaleUp,
        yScale     = scaleUp,
        transition = easing.outQuad,
        onComplete = function()
            obj._pulseHandle = transition.to(obj, {
                time       = duration,
                xScale     = 1,
                yScale     = 1,
                transition = easing.inQuad,
                onComplete = function()
                    obj._pulseHandle = nil
                    obj:setFillColor(unpack(normalColor))
                end,
            })
        end,
    })
end

return M
