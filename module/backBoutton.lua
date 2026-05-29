-- backBoutton.lua
local function createBackButton(onBack)
    local button = display.newCircle(30, display.contentHeight - 30, 12.5)
    button:setFillColor(0, 0, 1)

    local buttonText = display.newText({
        text = "Retour",
        x = 100, y = display.contentHeight - 30,
        font = native.systemFont,
        fontSize = 30
    })
    buttonText:setFillColor(1, 1, 1)

    button:addEventListener("tap", function()
        if onBack then onBack() end
    end)

    return button, buttonText
end

return createBackButton