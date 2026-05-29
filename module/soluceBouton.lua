-----------------------------------------------------------------------------------------
--
-- soluceBouton.lua
--
-----------------------------------------------------------------------------------------

local M = {}
local utils = require("module.utils")

function M(grid, gridBlank, gridOffsetX, gridOffsetY, cellSize, duration)
    local button = display.newCircle(30, display.contentHeight - 110, 12.5)
    button:setFillColor(1, 0, 0)

    local isActive = true
    local outlines = {}
    local hue = 0
    local rainbowTimer = nil

    button:addEventListener("tap", function()
        if rainbowTimer then
            timer.cancel(rainbowTimer)
        end

        isActive = true
        hue = 0
        outlines = {}

        for i = 1, #grid do
            for j = 1, #grid[i] do
                local correctVal = grid[i][j]
                local userVal = gridBlank[i][j]

                if correctVal ~= 99 and correctVal ~= userVal then
                    local x = gridOffsetX + (j - 1) * cellSize - (cellSize / 2)
                    local y = gridOffsetY + (i - 1) * cellSize - (cellSize / 2)

                    local outline = display.newRect(x, y, cellSize, cellSize)
                    outline.anchorX = 0
                    outline.anchorY = 0
                    outline:setFillColor(0, 0, 0, 0)
                    outline.strokeWidth = 3
                    outline:setStrokeColor(1, 0, 1)

                    table.insert(outlines, outline)
                end
            end
        end

        rainbowTimer = timer.performWithDelay(100, function()
            if not isActive then return end

            hue = (hue + 0.05) % 1
            local r, g, b = utils.hsvToRgb(hue, 1, 1)

            for _, outline in ipairs(outlines) do
                if outline and outline.setStrokeColor then
                    outline:setStrokeColor(r, g, b)
                end
            end

            if button and button.setFillColor then
                button:setFillColor(r, g, b)
            end
        end, 0)

        timer.performWithDelay(duration * 1000, function()
            isActive = false

            if rainbowTimer then
                timer.cancel(rainbowTimer)
            end

            for _, outline in ipairs(outlines) do
                if outline and outline.removeSelf then
                    outline:removeSelf()
                end
            end
            outlines = {}
        end)
    end)
    return button
end

return M
