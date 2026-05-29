-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- main.lua
local composer = require("composer")

-- Charge la scène initiale
composer.gotoScene("swapScreen.Title")
