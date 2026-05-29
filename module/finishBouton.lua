-- finishBouton.lua

local function createFinishButton(onFinish)
    local button = display.newCircle(30, display.contentHeight - 70, 12.5)
    button:setFillColor(0, 1, 0)
    button:addEventListener("tap", function()
        if onFinish then onFinish() end
    end)
    return button
end

return createFinishButton