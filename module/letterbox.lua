local M = {}

-- TODO : ces bordures chaudes seront remplacées par une image ou un espace d'animation (décor, effets, mascotte...)
local function drawHatchedBand(cx, cy, w, h, sceneGroup)
    if w <= 2 or h <= 2 then return end

    local container = display.newContainer(w, h)
    container.x = cx
    container.y = cy

    local bg = display.newRect(0, 0, w, h)
    bg:setFillColor(0.12, 0.09, 0.07)   -- bg sombre chaud
    container:insert(bg)

    local stripe = 14
    local total  = w + h
    for i = -total, total, stripe * 2 do
        local line = display.newLine(i, h / 2, i + h, -h / 2)
        line.strokeWidth = stripe
        line:setStrokeColor(0.50, 0.34, 0.17)   -- frame brun moyen
        container:insert(line)
    end

    local border = display.newRect(0, 0, w - 2, h - 2)
    border:setFillColor(0, 0, 0, 0)
    border.strokeWidth = 3
    border:setStrokeColor(0.50, 0.34, 0.17)   -- frame brun moyen
    container:insert(border)

    sceneGroup:insert(container)
end

function M.draw(sceneGroup)
    local ox = display.screenOriginX
    local oy = display.screenOriginY
    local aw = display.actualContentWidth
    local ah = display.actualContentHeight
    local cw = display.contentWidth
    local ch = display.contentHeight

    local lw = -ox
    if lw > 1 then
        local by = oy + ah / 2
        drawHatchedBand(ox + lw / 2, by, lw, ah, sceneGroup)
        drawHatchedBand(cw + lw / 2, by, lw, ah, sceneGroup)
    end

    local th = -oy
    if th > 1 then
        local bx = ox + aw / 2
        drawHatchedBand(bx, oy + th / 2, aw, th, sceneGroup)
        drawHatchedBand(bx, ch + th / 2, aw, th, sceneGroup)
    end
end

return M
