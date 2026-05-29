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



return M
