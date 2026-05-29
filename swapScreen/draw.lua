-----------------------------------------------------------------------------------------
--
-- draw.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

function scene:create(event)
    local sceneGroup = self.view

    -- Pré-déclaré ici pour que les closures définies avant son require() y accèdent
    local deleteButton

    self.gridRects = {}
    self.carreList = {}

    local letPuzzle   = composer.getVariable("selectedPuzzle")
    local selectedPage = composer.getVariable("selectedPage") or 1
    local selectMAP   = require("data.drawMap" .. selectedPage)
    local colorMap    = require("data.colorMap")
    local compass     = require("module.compass")
    local animation   = require("module.animation")

    local map  = selectMAP[letPuzzle]
    local grid = map.grid

    local cellMiniSize = map.data.miniSize
    local cellLargeur  = map.data.Largeur
    local cellHauteur  = map.data.Hauteur

    local offsetX = 15
    local offsetY = 20

    local gridBlank   = {}
    local textColorNb = {}

    -- ─── Victoire ───────────────────────────────────────────────────────────────
    local function showFinitoMessage()
        local finitoText = display.newText({
            text = "FINITO",
            x = display.contentCenterX,
            y = display.contentHeight - 30,
            font = native.systemFontBold,
            fontSize = 28
        })
        finitoText:setFillColor(0, 1, 0)
    end

    local function countGridDifferences(grid1, grid2)
        local value = 0
        for y = 1, #grid1 do
            for x = 1, #grid1[y] do
                if grid1[y][x] ~= grid2[y][x] then
                    value = value + 1
                end
            end
        end
        return value
    end

    -- ─── Helpers couleur ────────────────────────────────────────────────────────
    local function restockColor(k)
        map.data.colorsNb[k] = map.data.colorsNb[k] + 1
        if textColorNb[k] then
            textColorNb[k].text = "x " .. map.data.colorsNb[k]
        end
    end

    -- ─── Mini-carte (aperçu du puzzle) ──────────────────────────────────────────
    for y = 1, #grid do
        for x = 1, #grid[y] do
            local value = grid[y][x]
            local color = colorMap[value] or {1, 1, 1}

            local rect = display.newRect(
                offsetX + (x - 1) * cellMiniSize,
                offsetY + (y - 1) * cellMiniSize,
                cellMiniSize, cellMiniSize
            )
            rect:setFillColor(unpack(color))
            rect.anchorX = 0
            rect.anchorY = 0
            sceneGroup:insert(rect)

            if value == 99 then
                local whiteSize = cellMiniSize * 0.3
                local cx = offsetX + (x - 1) * cellMiniSize + cellMiniSize / 2
                local cy = offsetY + (y - 1) * cellMiniSize + cellMiniSize / 2
                local whiteSquare = display.newRect(cx, cy, whiteSize, whiteSize)
                whiteSquare:setFillColor(1, 1, 1)
                sceneGroup:insert(whiteSquare)
            end
        end
    end

    -- ─── Infos puzzle ───────────────────────────────────────────────────────────
    local infoY = offsetY + (#grid * cellMiniSize) + 20

    local puzzleText = display.newText({
        text = "Puzzle #" .. map.num,
        x = offsetX + 5, y = infoY,
        font = native.systemFontBold, fontSize = 18
    })
    puzzleText.anchorX = 0
    sceneGroup:insert(puzzleText)

    local titleText = display.newText({
        text = "Name: " .. map.data.name,
        x = offsetX + 5, y = infoY + 25,
        font = native.systemFont, fontSize = 16
    })
    titleText.anchorX = 0
    sceneGroup:insert(titleText)

    local difficultyText = display.newText({
        text = "Difficulty: " .. map.data.difficulty,
        x = offsetX + 5, y = infoY + 45,
        font = native.systemFont, fontSize = 16
    })
    difficultyText.anchorX = 0
    sceneGroup:insert(difficultyText)

    -- ─── Paramètres grille ──────────────────────────────────────────────────────
    local cellSize    = map.data.cellSize
    local gridOffsetX = map.data.posX
    local gridOffsetY = map.data.posY
    local rows        = map.data.Hauteur
    local cols        = map.data.Largeur

    -- ─── Compteurs de pixels ────────────────────────────────────────────────────
    local pixCountTotal = 0
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x] ~= 99 then
                pixCountTotal = pixCountTotal + 1
            end
        end
    end

    -- Compass mini-carte
    for i = 1, cellHauteur do
        compass.randowX(5, cellMiniSize - 2, cellMiniSize)
    end
    for i = 1, cellLargeur do
        compass.randowY(10, cellMiniSize - 2, cellMiniSize)
    end

    local pixCountText = display.newText({
        text = pixCountTotal,
        x = display.contentWidth - 30,
        y = map.data.totalY,
        font = native.systemFont,
        fontSize = 30,
        align = "right"
    })
    pixCountText.anchorX = 1
    pixCountText:setFillColor(1, 1, 1)
    sceneGroup:insert(pixCountText)

    local diffCount2 = pixCountTotal

    local diffCountText = display.newText({
        text = tostring(diffCount2),
        x = display.contentWidth - 80,
        y = map.data.countY,
        font = native.systemFont,
        fontSize = 30,
        align = "right"
    })
    diffCountText.anchorX = 1
    diffCountText:setFillColor(1, 1, 1)
    sceneGroup:insert(diffCountText)

    -- ─── État palette (pré-déclarés pour les closures onCellTouch / onMouseEvent) ─
    local arrowList    = {}
    local firstArrow
    local currentIndex = 1
    local drawPixel    = nil

    -- ─── Effacement d'une cellule ───────────────────────────────────────────────
    local function eraseCell(rect, i, j)
        local cellColor = gridBlank[i][j]
        if cellColor == 99 then return end

        for k = 1, #map.data.colors do
            if map.data.colors[k] == cellColor then
                restockColor(k)
                break
            end
        end

        gridBlank[i][j] = 99
        rect:setFillColor(unpack(colorMap[99]))
        animation.ringBoom(rect.x, rect.y, colorMap[cellColor], scene.view)

        if not rect.marker then
            local marker = display.newRect(rect.x, rect.y, 3, 3)
            marker:setFillColor(1, 1, 1)
            rect.marker = marker
        end
    end

    -- ─── Touch sur la grille ────────────────────────────────────────────────────
    local function onCellTouch(event)
        local rect  = event.target
        local phase = event.phase

        if phase == "began" then
            rect.touchStartTime = system.getTimer()
            display.getCurrentStage():setFocus(rect)
            rect.isFocus = true

        elseif rect.isFocus then
            if phase == "ended" or phase == "cancelled" then
                display.getCurrentStage():setFocus(nil)
                rect.isFocus = false

                local elapsed = system.getTimer() - rect.touchStartTime
                local i, j   = rect.i, rect.j

                if elapsed > 300 or deleteButton.isDeleteMode() then
                    -- Clic long OU mode suppression : effacement
                    eraseCell(rect, i, j)
                else
                    -- Mode peinture normal
                    local newColor = drawPixel

                    if gridBlank[i][j] == newColor then return true end

                    local canPlace   = false
                    local colorIndex = nil
                    for k = 1, #map.data.colors do
                        if map.data.colors[k] == newColor then
                            colorIndex = k
                            if map.data.colorsNb[k] > 0 then
                                canPlace = true
                            end
                            break
                        end
                    end

                    if not canPlace then return true end

                    -- Remettre l'ancienne couleur en stock si la case n'était pas vide
                    if gridBlank[i][j] ~= 99 then
                        for k = 1, #map.data.colors do
                            if map.data.colors[k] == gridBlank[i][j] then
                                restockColor(k)
                                break
                            end
                        end
                    end

                    gridBlank[i][j] = newColor
                    rect:setFillColor(unpack(colorMap[newColor]))
                    animation.fireWork(rect.x, rect.y, colorMap[newColor], scene.view)

                    if rect.marker then
                        rect.marker:removeSelf()
                        rect.marker = nil
                    end

                    map.data.colorsNb[colorIndex] = map.data.colorsNb[colorIndex] - 1
                    if textColorNb[colorIndex] then
                        textColorNb[colorIndex].text = "x " .. map.data.colorsNb[colorIndex]
                    end
                end

                diffCount2 = countGridDifferences(grid, gridBlank)
                diffCountText.text = tostring(diffCount2)
                if diffCount2 == 0 then
                    showFinitoMessage()
                end
            end
        end

        return true
    end

    -- ─── Grille vierge interactive ──────────────────────────────────────────────
    for i = 1, rows do
        self.gridRects[i] = {}
        gridBlank[i] = {}
        for j = 1, cols do
            local x = gridOffsetX + (j - 1) * cellSize
            local y = gridOffsetY + (i - 1) * cellSize

            local rect = display.newRect(x, y, cellSize, cellSize)
            rect:setFillColor(unpack(colorMap[99]))
            rect.i = i
            rect.j = j
            sceneGroup:insert(rect)
            table.insert(self.gridRects[i], rect)

            gridBlank[i][j] = 99

            local marker = display.newRect(x, y, 3, 3)
            marker:setFillColor(1, 1, 1)
            rect.marker = marker
            sceneGroup:insert(marker)

            rect:addEventListener("touch", onCellTouch)
        end
    end

    -- ─── Compass grille principale ──────────────────────────────────────────────
    local borderOffset   = math.max(30, cellSize + 5)
    local decalageHaut   = math.floor(cellSize * 0.5)
    local decalageGauche = math.floor(cellSize * 0.5)
    local borderX = gridOffsetX - borderOffset
    local borderY = gridOffsetY - borderOffset

    for i = 1, rows do
        compass.randowX2(i, gridOffsetY, borderX, cellSize - 2, cellSize, decalageHaut)
    end
    for j = 1, cols do
        compass.randowY2(j, gridOffsetX, borderY, cellSize - 2, cellSize, decalageGauche)
    end

    -- ─── Palette de couleurs ────────────────────────────────────────────────────
    local startX  = 930
    local startY  = 30
    local spacing = 10

    for i = 1, #map.data.colors do
        local colorName = map.data.colors[i]
        local colorNb   = map.data.colorsNb[i]

        local carre = display.newRect(startX, startY, cellSize, cellSize)
        carre:setFillColor(unpack(colorMap[colorName]))
        carre.colorValue = colorName
        carre.index = i
        sceneGroup:insert(carre)
        table.insert(self.carreList, carre)

        local arrow = display.newPolygon(startX - 30, startY, {0, -10, 0, 10, 15, 0})
        arrow:setFillColor(1, 1, 1)
        arrow.isVisible = false
        sceneGroup:insert(arrow)
        table.insert(arrowList, arrow)

        if i == 1 then
            firstArrow = arrow
            drawPixel  = colorName
        end

        carre:addEventListener("tap", function(event)
            drawPixel    = event.target.colorValue
            currentIndex = event.target.index
            deleteButton.updateDeleteMode(false)

            for _, a in ipairs(arrowList) do
                a.isVisible = false
            end
            arrowList[currentIndex].isVisible = true
            return true
        end)

        textColorNb[i] = display.newText({
            text = "x " .. colorNb,
            x = startX + cellSize + 15,
            y = startY - 8,
            font = native.systemFont,
            fontSize = 18
        })
        textColorNb[i].anchorY = 0
        textColorNb[i]:setFillColor(1, 1, 1)
        sceneGroup:insert(textColorNb[i])

        startY = startY + cellSize + spacing
    end

    if firstArrow then
        firstArrow.isVisible = true
    end

    native.setProperty("mouseCursorVisible", true)

    -- ─── Molette souris ─────────────────────────────────────────────────────────
    local function onMouseEvent(event)
        if event.scrollY and event.scrollY ~= 0 then
            if event.scrollY > 0 then
                currentIndex = currentIndex + 1
            else
                currentIndex = currentIndex - 1
            end

            if currentIndex < 1 then
                currentIndex = #map.data.colors
            elseif currentIndex > #map.data.colors then
                currentIndex = 1
            end

            drawPixel = map.data.colors[currentIndex]
            deleteButton.updateDeleteMode(false)

            for _, a in ipairs(arrowList) do
                a.isVisible = false
            end
            arrowList[currentIndex].isVisible = true
        end
        return false
    end

    -- Stocké sur scene pour pouvoir le retirer dans scene:destroy
    scene.onMouseEvent = onMouseEvent
    Runtime:addEventListener("mouse", onMouseEvent)

    -- ─── Boutons dev ────────────────────────────────────────────────────────────
    local finishUp     = require("module.finishBouton")
    local finishButton = finishUp(function()
        diffCount2 = 0
        diffCountText.text = tostring(diffCount2)
        showFinitoMessage()
        compass.resetCounters()
    end)
    sceneGroup:insert(finishButton)

    local finishButtonText = display.newText({
        text = "Fin",
        x = 80,
        y = display.contentHeight - 70,
        font = native.systemFont,
        fontSize = 30,
        align = "right"
    })
    sceneGroup:insert(finishButtonText)

    local soluceUp     = require("module.soluceBouton")
    local soluceButton = soluceUp(grid, gridBlank, gridOffsetX, gridOffsetY, cellSize, 5)
    sceneGroup:insert(soluceButton)

    local soluceButtonText = display.newText({
        text = "Soluce",
        x = 100,
        y = display.contentHeight - 110,
        font = native.systemFont,
        fontSize = 30,
        align = "right"
    })
    sceneGroup:insert(soluceButtonText)

    -- ─── Bouton Retour ──────────────────────────────────────────────────────────
    local function onAbortDraw()
        compass.resetCounters()
        deleteButton.cancelBlinkTimer()
        deleteButton.removeCustomCursor()
        Runtime:removeEventListener("mouse", scene.onMouseEvent)
        composer.gotoScene("swapScreen.selectDraw", {time = 500, effect = "fade"})
        composer.removeScene("swapScreen.draw")
    end

    -- Rechargement forcé pour recréer les objets UI du module à chaque partie
    package.loaded["module.deleteButton"] = nil
    deleteButton = require("module.deleteButton")
    deleteButton.init({
        map          = map,
        arrowList    = arrowList,
        currentIndex = currentIndex
    })
    sceneGroup:insert(deleteButton.yellowButton)
    sceneGroup:insert(deleteButton.yellowButtonText)

    local createBackButton            = require("module.backBoutton")
    local retourButton, retourButtonText = createBackButton(onAbortDraw)
    sceneGroup:insert(retourButton)
    sceneGroup:insert(retourButtonText)
end

scene:addEventListener("create", scene)

function scene:destroy(event)
    -- Filet de sécurité : retire le listener si la scène est détruite sans passer par onAbortDraw
    Runtime:removeEventListener("mouse", scene.onMouseEvent)
end

scene:addEventListener("destroy", scene)

return scene
