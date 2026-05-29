local composer = require("composer")
local scene = composer.newScene()

-- 📦 Importation des couleurs
local ColorMiniDraw = require("data.colorMap")

-- 📦 Fonction de chargement dynamique des puzzles
local function loadDataMap(page)
    local moduleName = "data.drawMap" .. page
    package.loaded[moduleName] = nil -- Force le rechargement
    return require(moduleName)
end

-- 📄 Variables globales à la scène
local pageCurrent = 1
local pageMax = 3
local dataMap = loadDataMap(pageCurrent)
local sceneGroup
local pageIndicator
local leftArrow
local rightArrow

-- 📐 Grille
local squareSize = 230
local spacing = 20
local numRows = 2
local numCols = 3
local ajustY = 50

local gridWidth = numCols * squareSize + (numCols - 1) * spacing
local gridHeight = numRows * squareSize + (numRows - 1) * spacing
local startX = (display.contentCenterX - gridWidth / 2)
local startY = (display.contentCenterY - gridHeight / 2) + ajustY - 30

-- Fonction pour récupérer les bornes utiles du puzzle (non 99)
local function getPuzzleBounds(grid)
    local minRow, maxRow = #grid, 1
    local minCol, maxCol = #grid[1], 1

    for row = 1, #grid do
        for col = 1, #grid[row] do
            if grid[row][col] ~= 99 then
                if row < minRow then minRow = row end
                if row > maxRow then maxRow = row end
                if col < minCol then minCol = col end
                if col > maxCol then maxCol = col end
            end
        end
    end

    local height = maxRow - minRow + 1
    local width = maxCol - minCol + 1
    return minRow, minCol, height, width
end

-- 🧱 Dessin de la grille
local function drawGrid()
    local idCounter = 1
    for row = 0, numRows - 1 do
        for col = 0, numCols - 1 do
            local x = startX + col * (squareSize + spacing) + squareSize / 2
            local y = startY + row * (squareSize + spacing) + squareSize / 2

            local mapData = dataMap[idCounter]

            if mapData then
                
                -- 🟫 Carré de fond
                local square = display.newRect(sceneGroup, x, y, squareSize, squareSize)
                square:setFillColor(0.3, 0.3, 0.3)
                square:setStrokeColor(1)
                square.isPuzzleElement = true

                square.idNom = mapData.num
                square.grid = mapData.grid
                square.difficulty = mapData.data.difficulty
                square.clear = mapData.data.Clear
                square.unlock = mapData.data.Unlock
                square.name = mapData.data.name

                -- 📏 Calculs d’adaptation à une taille unique
                local grid = mapData.grid
                local minRow, minCol, height, width = getPuzzleBounds(grid)
                local maxCells = math.max(width, height)
                local maxRenderSize = squareSize * 0.8
                local cellSize = maxRenderSize / maxCells
                local offsetX = x - (width * cellSize) / 2
                local offsetY = y - (height * cellSize) / 2

                -- 🎨 Rendu des pixels miniatures
                for r = minRow, minRow + height - 1 do
                    for c = minCol, minCol + width - 1 do
                        local value = grid[r][c]
                        if value ~= 99 then
                            local color = ColorMiniDraw[value] or {1, 1, 1}
                            local px = offsetX + (c - minCol) * cellSize
                            local py = offsetY + (r - minRow) * cellSize

                            local pixel = display.newRect(sceneGroup, px, py, cellSize, cellSize)
                            pixel:setFillColor(unpack(color))
                            pixel.anchorX = 0
                            pixel.anchorY = 0
                            pixel.isPuzzleElement = true
                        end
                    end
                end

                local selectedId = mapData.num
                local currentPage = pageCurrent
                square:addEventListener("tap", function()
                    composer.removeScene("swapScreen.selectDraw")
                    composer.setVariable("selectedPuzzle", selectedId)
                    composer.setVariable("selectedPage", currentPage)
                    composer.gotoScene("swapScreen.draw", { effect = "crossFade", time = 500 })
                end)
            else
                -- 🞬 Case vide avec croix
                local square = display.newRect(sceneGroup, x, y, squareSize, squareSize)
                square:setFillColor(0.3, 0.3, 0.3)
                square:setStrokeColor(0.3)
                square.strokeWidth = 2
                square.isPuzzleElement = true

                local offset = squareSize * 0.4
                local line1 = display.newLine(sceneGroup, x - offset, y - offset, x + offset, y + offset)
                local line2 = display.newLine(sceneGroup, x - offset, y + offset, x + offset, y - offset)

                for _, line in ipairs({line1, line2}) do
                    line:setStrokeColor(0, 0, 0)
                    line.strokeWidth = 4
                    line.isPuzzleElement = true
                end
            end

            idCounter = idCounter + 1
        end
    end
end

-- 🔁 Nettoyage de la grille précédente
local function clearGrid()
    for i = sceneGroup.numChildren, 1, -1 do
        local child = sceneGroup[i]
        if child.isPuzzleElement then
            display.remove(child)
        end
    end
end

-- 🔺 Mise à jour des flèches et page
local function updatePageDisplay()
    pageIndicator.text = pageCurrent .. " / " .. pageMax
    leftArrow.isVisible, leftArrow.isHitTestable = pageCurrent > 1, pageCurrent > 1
    rightArrow.isVisible, rightArrow.isHitTestable = pageCurrent < pageMax, pageCurrent < pageMax
end

-- 🔺 Flèches
local function createArrow(points, x, y, fill, stroke, onTap)
    local arrow = display.newPolygon(sceneGroup, x, y + 20, points)
    arrow:setFillColor(unpack(fill))
    arrow.strokeWidth = 2
    arrow:setStrokeColor(unpack(stroke))

    arrow:addEventListener("tap", function()
        arrow:setFillColor(1, 0.5, 0)
        timer.performWithDelay(150, function()
            arrow:setFillColor(unpack(fill))
        end)
        onTap()
    end)

    return arrow
end

-- 🔨 Création de la scène
function scene:create(event)
    sceneGroup = self.view

    local letterbox = require("module.letterbox")
    letterbox.draw(sceneGroup)

    -- Bouton retour (haut gauche)
    local backBtn = display.newText({
        parent = sceneGroup,
        text = "←",
        x = 50,
        y = 45,
        font = native.systemFontBold,
        fontSize = 48
    })
    backBtn:setFillColor(0.7, 0.7, 0.7)
    backBtn.isHitTestable = true
    backBtn:addEventListener("tap", function()
        composer.gotoScene("swapScreen.Title", {effect = "fade", time = 400})
    end)

    local title = display.newText({
        parent = sceneGroup,
        text = "Sélectionnez un dessin",
        x = display.contentCenterX,
        y = 80,
        font = native.systemFontBold,
        fontSize = 36
    })
    title:setFillColor(0.5, 0.5, 0.5)

    pageIndicator = display.newText({
        parent = sceneGroup,
        text = pageCurrent .. " / " .. pageMax,
        x = display.contentCenterX,
        y = display.contentHeight * 0.92,
        font = native.systemFontBold,
        fontSize = 36
    })
    pageIndicator:setFillColor(0.5, 0.5, 0.5)

    -- ➡️ Flèche droite
    local size = 40
    rightArrow = createArrow(
        {0, -size, 0, size, size, 0},
        display.contentWidth - 60, display.contentCenterY,
        {0.6, 0.6, 1}, {0.3, 0.3, 0.6},
        function()
            if pageCurrent < pageMax then
                pageCurrent = pageCurrent + 1
                clearGrid()
                dataMap = loadDataMap(pageCurrent)
                drawGrid()
                updatePageDisplay()
            end
        end
    )

    -- ⬅️ Flèche gauche
    leftArrow = createArrow(
        {0, -size, 0, size, -size, 0},
        60, display.contentCenterY,
        {0.6, 0.6, 1}, {0.3, 0.3, 0.6},
        function()
            if pageCurrent > 1 then
                pageCurrent = pageCurrent - 1
                clearGrid()
                dataMap = loadDataMap(pageCurrent)
                drawGrid()
                updatePageDisplay()
            end
        end
    )

    drawGrid()
    updatePageDisplay()
end

scene:addEventListener("create", scene)
return scene