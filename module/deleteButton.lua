-----------------------------------------------------------------------------------------
--
-- deleteButton.lua
--
-----------------------------------------------------------------------------------------

local N = {}
local utils = require("module.utils")

local group = display.newGroup()
local customCursorImage

local deletePix = false
local drawPixel = nil
local arrowList = nil
local map = nil

local function onMouseMove(event)
    local x, y = event.x, event.y
    group.x, group.y = x, y
    group:toFront()
end

function N.setCustomCursor(imagePath, width, height, ancrageX, ancrageY)
    if customCursorImage then
        customCursorImage:removeSelf()
        customCursorImage = nil
    end

    customCursorImage = display.newImageRect(group, imagePath, width or 32, height or 32)
    customCursorImage.anchorX = ancrageX
    customCursorImage.anchorY = ancrageY
    customCursorImage.x, customCursorImage.y = 0, 0

    native.setProperty("mouseCursorVisible", false)

    Runtime:removeEventListener("mouse", onMouseMove)
    Runtime:addEventListener("mouse", onMouseMove)
end

function N.removeCustomCursor()
    if customCursorImage then
        customCursorImage:removeSelf()
        customCursorImage = nil
    end
    native.setProperty("mouseCursorVisible", true)
    Runtime:removeEventListener("mouse", onMouseMove)
end

function N.isDeleteMode()
    return deletePix
end

local yellowButton = display.newCircle(30, display.contentHeight - 150, 12.5)
yellowButton:setFillColor(1, 1, 0)

local yellowButtonText = display.newText({
    text = "Effacer",
    x = 100,
    y = display.contentHeight - 150,
    font = native.systemFont,
    fontSize = 30,
    align = "right"
})

local hue = 0
local blinkTimerId = timer.performWithDelay(100, function()
    if deletePix then
        hue = (hue + 0.08) % 1
        local r, g, b = utils.hsvToRgb(hue, 1, 1)
        yellowButton:setFillColor(r, g, b)
    else
        yellowButton:setFillColor(1, 1, 0)
    end
end, 0)

function N.cancelBlinkTimer()
    if blinkTimerId then
        timer.cancel(blinkTimerId)
        blinkTimerId = nil
    end
end

local function updateDeleteMode(isDelete)
    deletePix = isDelete
    if deletePix then
        drawPixel = nil
        N.setCustomCursor("img/crossRed.png", 32, 32, 0.5, 0.5)
        if arrowList then
            for _, a in ipairs(arrowList) do
                a.isVisible = false
            end
        end
    else
        if map and currentIndex and map.data and map.data.colors then
            drawPixel = map.data.colors[currentIndex]
        end
        N.setCustomCursor("img/penIcon.png", 32, 32, 0, 1)
        if arrowList and currentIndex and arrowList[currentIndex] then
            arrowList[currentIndex].isVisible = true
        end
    end
end

local function onYellowButtonClick(event)
    if event.phase == "ended" then
        updateDeleteMode(not deletePix)
    end
    return true
end

yellowButton:addEventListener("touch", onYellowButtonClick)

function N.init(params)
    map = params.map
    arrowList = params.arrowList
    currentIndex = params.currentIndex
    updateDeleteMode(false)
end

function N.updateDeleteMode(isDelete)
    updateDeleteMode(isDelete)
end

N.yellowButton = yellowButton
N.yellowButtonText = yellowButtonText

return N
