local composer = require("composer")
local scene = composer.newScene()

function scene:create(event)
    local sceneGroup = self.view
    local deleteButton

    self.gridRects = {}
    self.carreList = {}

    -- ─── Palette de couleurs (design chaud, copie de selectDraw) ────────────
    local C = {
        bg        = {0.12, 0.09, 0.07},
        frame     = {0.50, 0.34, 0.17},
        frameShad = {0.30, 0.20, 0.10},
        canvas    = {0.19, 0.14, 0.11},
        nav       = {0.24, 0.17, 0.11},
        navArrow  = {0.94, 0.76, 0.38},
        title     = {0.98, 0.88, 0.62},
        sub       = {0.68, 0.52, 0.35},
        accent    = {0.96, 0.72, 0.24},
    }

    local letterbox = require("module.letterbox")
    letterbox.draw(sceneGroup)

    -- Fond chaud
    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY,
                               display.contentWidth, display.contentHeight)
    bg:setFillColor(unpack(C.bg))

    local letPuzzle    = composer.getVariable("selectedPuzzle")
    local selectedPage = composer.getVariable("selectedPage") or 1
    local selectMAP    = require("data.drawMap" .. selectedPage)
    local colorMap     = require("data.colorMap")
    local compass      = require("module.compass")
    local animation    = require("module.animation")
    local utils        = require("module.utils")

    local map  = selectMAP[letPuzzle]
    local grid = map.grid

    local cellMiniSize = map.data.miniSize
    local cellLargeur  = map.data.Largeur
    local cellHauteur  = map.data.Hauteur

    local offsetX = 38
    local offsetY = 20

    local gridBlank   = {}
    local textColorNb = {}

    -- ─── Victoire ────────────────────────────────────────────────────────────
    local function showFinitoMessage()
        local finitoText = display.newText({
            text     = "FINITO",
            x        = display.contentCenterX,
            y        = display.contentHeight - 30,
            font     = native.systemFontBold,
            fontSize = 28,
        })
        finitoText:setFillColor(unpack(C.accent))
        sceneGroup:insert(finitoText)
    end

    local function countGridDifferences(g1, g2)
        local v = 0
        for y = 1, #g1 do
            for x = 1, #g1[y] do
                if g1[y][x] ~= g2[y][x] then v = v + 1 end
            end
        end
        return v
    end

    -- ─── Helpers couleur ─────────────────────────────────────────────────────
    local function restockColor(k)
        map.data.colorsNb[k] = map.data.colorsNb[k] + 1
        if textColorNb[k] then
            textColorNb[k].text = tostring(map.data.colorsNb[k])
        end
    end

    -- ─── Cadre mini-carte ────────────────────────────────────────────────────
    local miniW = cellLargeur * cellMiniSize
    local miniH = cellHauteur * cellMiniSize
    local miniCX = offsetX + miniW / 2
    local miniCY = offsetY + miniH / 2

    local miniShadow = display.newRect(sceneGroup, miniCX + 4, miniCY + 4, miniW + 18, miniH + 18)
    miniShadow:setFillColor(0, 0, 0, 0.5)

    local miniFrame = display.newRect(sceneGroup, miniCX, miniCY, miniW + 14, miniH + 14)
    miniFrame:setFillColor(unpack(C.frame))
    miniFrame.strokeWidth = 2
    miniFrame:setStrokeColor(unpack(C.frameShad))

    local miniCanvas = display.newRect(sceneGroup, miniCX, miniCY, miniW, miniH)
    miniCanvas:setFillColor(unpack(C.canvas))

    -- ─── Mini-carte (pixels) ─────────────────────────────────────────────────
    for y = 1, #grid do
        for x = 1, #grid[y] do
            local value = grid[y][x]
            local color = colorMap[value] or {1, 1, 1}
            local rect  = display.newRect(
                offsetX + (x - 1) * cellMiniSize,
                offsetY + (y - 1) * cellMiniSize,
                cellMiniSize, cellMiniSize
            )
            rect:setFillColor(unpack(color))
            rect.anchorX = 0
            rect.anchorY = 0
            sceneGroup:insert(rect)

            if value == 99 then
                local ws = cellMiniSize * 0.3
                local cx = offsetX + (x - 1) * cellMiniSize + cellMiniSize / 2
                local cy = offsetY + (y - 1) * cellMiniSize + cellMiniSize / 2
                local wsq = display.newRect(cx, cy, ws, ws)
                wsq:setFillColor(1, 1, 1)
                sceneGroup:insert(wsq)
            end
        end
    end

    -- ─── Paramètres grille ───────────────────────────────────────────────────
    local cellSize = map.data.cellSize
    local rows     = map.data.Hauteur
    local cols     = map.data.Largeur

    -- Repositionnement dynamique : utilise l'espace libéré par le panneau droit supprimé
    local leftBound  = offsetX + miniW + 45
    local rightBound = display.contentWidth - 15
    local topBound   = 15
    local botBound   = display.contentHeight - 55
    local gridOffsetX = math.floor(leftBound + (rightBound - leftBound - cols * cellSize) / 2 + cellSize / 2)
    local gridOffsetY = math.floor(topBound  + (botBound  - topBound  - rows * cellSize) / 2 + cellSize / 2)

    -- Bornes de la grille
    local gridLeft    = gridOffsetX - cellSize / 2
    local gridRight   = gridOffsetX + (cols - 1) * cellSize + cellSize / 2
    local gridTop     = gridOffsetY - cellSize / 2
    local gridBottom  = gridOffsetY + (rows - 1) * cellSize + cellSize / 2
    local borderOffset = math.max(30, cellSize + 5)
    local labelTopY   = gridTop - borderOffset - 14   -- au-dessus du repère de couleurs
    local labelBotY   = gridBottom + 18               -- indicateur bas-droit

    -- Nom (haut-gauche, au-dessus du repère)
    local nameLabel = display.newText({
        text = map.data.name, x = gridLeft, y = labelTopY,
        font = native.systemFontBold, fontSize = 15,
    })
    nameLabel.anchorX = 0
    nameLabel:setFillColor(unpack(C.title))
    sceneGroup:insert(nameLabel)

    -- Difficulté (haut-droit, au-dessus du repère)
    local diffLabel = display.newText({
        text = map.data.difficulty, x = gridRight, y = labelTopY,
        font = native.systemFont, fontSize = 13,
    })
    diffLabel.anchorX = 1
    diffLabel:setFillColor(unpack(C.sub))
    sceneGroup:insert(diffLabel)

    -- ─── Compteurs ───────────────────────────────────────────────────────────
    local pixCountTotal = 0
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x] ~= 99 then pixCountTotal = pixCountTotal + 1 end
        end
    end

    local mSize  = cellMiniSize - 2
    local mHalf  = math.floor(mSize / 2)
    -- Repères lignes : bande colorée à gauche de la mini-carte
    for i = 1, cellHauteur do
        compass.randowX(offsetX - mHalf - 3, mSize, cellMiniSize, offsetY)
    end
    -- Repères colonnes : bande colorée au-dessus de la mini-carte
    for i = 1, cellLargeur do
        compass.randowY(offsetY - mHalf - 3, mSize, cellMiniSize, offsetX)
    end

    -- Indicateurs pixel (bas-droit, horizontaux : restant #1 | total #2)
    local diffCount2 = pixCountTotal
    local diffCountText = display.newText({
        text = tostring(diffCount2),
        x = gridRight - 48, y = labelBotY,
        font = native.systemFontBold, fontSize = 18, align = "right",
    })
    diffCountText.anchorX = 1
    diffCountText:setFillColor(unpack(C.accent))
    sceneGroup:insert(diffCountText)

    local pixCountText = display.newText({
        text = tostring(pixCountTotal),
        x = gridRight, y = labelBotY,
        font = native.systemFontBold, fontSize = 15, align = "right",
    })
    pixCountText.anchorX = 1
    pixCountText:setFillColor(unpack(C.sub))
    sceneGroup:insert(pixCountText)

    -- ─── État palette ────────────────────────────────────────────────────────
    local currentIndex  = 1
    local drawPixel     = nil
    local selectedCarre = nil

    local function selectCarre(idx)
        if selectedCarre then
            selectedCarre.strokeWidth = 0
        end
        selectedCarre = self.carreList[idx]
        if selectedCarre then
            selectedCarre.strokeWidth = 4
            selectedCarre:setStrokeColor(1, 1, 1)
        end
    end

    -- ─── Effacement cellule ──────────────────────────────────────────────────
    local function eraseCell(rect, i, j)
        local cellColor = gridBlank[i][j]
        if cellColor == 99 then return end
        for k = 1, #map.data.colors do
            if map.data.colors[k] == cellColor then restockColor(k); break end
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

    -- ─── Touch grille ────────────────────────────────────────────────────────
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
                    eraseCell(rect, i, j)
                else
                    local newColor   = drawPixel
                    if gridBlank[i][j] == newColor then return true end
                    local canPlace   = false
                    local colorIndex = nil
                    for k = 1, #map.data.colors do
                        if map.data.colors[k] == newColor then
                            colorIndex = k
                            if map.data.colorsNb[k] > 0 then canPlace = true end
                            break
                        end
                    end
                    if not canPlace then return true end

                    if gridBlank[i][j] ~= 99 then
                        for k = 1, #map.data.colors do
                            if map.data.colors[k] == gridBlank[i][j] then
                                restockColor(k); break
                            end
                        end
                    end

                    gridBlank[i][j] = newColor
                    rect:setFillColor(unpack(colorMap[newColor]))
                    animation.fireWork(rect.x, rect.y, colorMap[newColor], scene.view)

                    if rect.marker then rect.marker:removeSelf(); rect.marker = nil end

                    map.data.colorsNb[colorIndex] = map.data.colorsNb[colorIndex] - 1
                    if textColorNb[colorIndex] then
                        textColorNb[colorIndex].text = tostring(map.data.colorsNb[colorIndex])
                    end
                end

                diffCount2 = countGridDifferences(grid, gridBlank)
                diffCountText.text = tostring(diffCount2)
                if diffCount2 == 0 then showFinitoMessage() end
            end
        end
        return true
    end

    -- ─── Grille interactive ──────────────────────────────────────────────────
    for i = 1, rows do
        self.gridRects[i] = {}
        gridBlank[i] = {}
        for j = 1, cols do
            local x = gridOffsetX + (j - 1) * cellSize
            local y = gridOffsetY + (i - 1) * cellSize
            local rect = display.newRect(x, y, cellSize, cellSize)
            rect:setFillColor(unpack(colorMap[99]))
            rect.i = i; rect.j = j
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

    -- ─── Compass grille principale ───────────────────────────────────────────
    local borderOffset   = math.max(30, cellSize + 5)
    local decalageHaut   = math.floor(cellSize * 0.5)
    local decalageGauche = math.floor(cellSize * 0.5)
    for i = 1, rows do
        compass.randowX2(i, gridOffsetY, gridOffsetX - borderOffset, cellSize - 2, cellSize, decalageHaut)
    end
    for j = 1, cols do
        compass.randowY2(j, gridOffsetX, gridOffsetY - borderOffset, cellSize - 2, cellSize, decalageGauche)
    end

    -- ─── Palette de couleurs (grille avec retour à la ligne) ────────────────
    local palSp       = 10
    local palStepX    = cellSize + palSp
    local palStepY    = cellSize + palSp
    local palY        = offsetY + cellHauteur * cellMiniSize + 36
    local itemsPerRow = math.max(1, math.floor((miniW + palSp) / palStepX))
    local rowWidth    = itemsPerRow * cellSize + (itemsPerRow - 1) * palSp
    local palStartX   = offsetX + math.floor((miniW - rowWidth) / 2)

    for i = 1, #map.data.colors do
        local colorName = map.data.colors[i]
        local colorNb   = map.data.colorsNb[i]
        local col = (i - 1) % itemsPerRow
        local row = math.floor((i - 1) / itemsPerRow)
        local px  = palStartX + col * palStepX
        local py  = palY + row * palStepY

        local frameRect = display.newRect(sceneGroup, px, py, cellSize + 4, cellSize + 4)
        frameRect:setFillColor(unpack(C.frame))

        local carre = display.newRect(px, py, cellSize, cellSize)
        carre:setFillColor(unpack(colorMap[colorName]))
        carre.colorValue = colorName
        carre.index      = i
        sceneGroup:insert(carre)
        table.insert(self.carreList, carre)

        if i == 1 then drawPixel = colorName end

        carre:addEventListener("tap", function(event)
            drawPixel    = event.target.colorValue
            currentIndex = event.target.index
            deleteButton.updateDeleteMode(false)
            selectCarre(currentIndex)
            return true
        end)

        textColorNb[i] = display.newText({
            text = tostring(colorNb), x = px, y = py,
            font = native.systemFontBold, fontSize = 13,
        })
        textColorNb[i]:setFillColor(1, 1, 1)
        sceneGroup:insert(textColorNb[i])
    end

    selectCarre(1)

    native.setProperty("mouseCursorVisible", true)

    -- ─── Molette souris ──────────────────────────────────────────────────────
    local function onMouseEvent(event)
        if event.scrollY and event.scrollY ~= 0 then
            currentIndex = event.scrollY > 0 and currentIndex + 1 or currentIndex - 1
            if currentIndex < 1 then currentIndex = #map.data.colors
            elseif currentIndex > #map.data.colors then currentIndex = 1 end
            drawPixel = map.data.colors[currentIndex]
            deleteButton.updateDeleteMode(false)
            selectCarre(currentIndex)
        end
        return false
    end
    scene.onMouseEvent = onMouseEvent
    Runtime:addEventListener("mouse", onMouseEvent)

    -- ─── Init deleteButton (logique) ─────────────────────────────────────────
    package.loaded["module.deleteButton"] = nil
    deleteButton = require("module.deleteButton")
    deleteButton.init({ map = map, arrowList = {}, currentIndex = currentIndex })
    deleteButton.yellowButton.alpha       = 0
    deleteButton.yellowButton.isHitTestable = false
    deleteButton.yellowButtonText.alpha   = 0
    sceneGroup:insert(deleteButton.yellowButton)
    sceneGroup:insert(deleteButton.yellowButtonText)

    -- ─── Callback retour ─────────────────────────────────────────────────────
    local function onAbortDraw()
        compass.resetCounters()
        deleteButton.cancelBlinkTimer()
        deleteButton.removeCustomCursor()
        Runtime:removeEventListener("mouse", scene.onMouseEvent)
        composer.gotoScene("swapScreen.selectDraw", {time = 500, effect = "fade"})
        composer.removeScene("swapScreen.draw")
    end

    -- ─── Modules boutons (logique conservée, cercles cachés) ─────────────────
    local finishUp     = require("module.finishBouton")
    local finishButton = finishUp(function()
        diffCount2 = 0
        diffCountText.text = tostring(diffCount2)
        showFinitoMessage()
        compass.resetCounters()
    end)
    finishButton.alpha         = 0
    finishButton.isHitTestable = false
    sceneGroup:insert(finishButton)

    local soluceUp     = require("module.soluceBouton")
    local soluceButton = soluceUp(grid, gridBlank, gridOffsetX, gridOffsetY, cellSize, 5)
    soluceButton.alpha         = 0
    soluceButton.isHitTestable = false
    sceneGroup:insert(soluceButton)

    local createBack              = require("module.backBoutton")
    local retourBtn, retourTxt    = createBack(onAbortDraw)
    retourBtn.alpha               = 0
    retourBtn.isHitTestable       = false
    retourTxt.alpha               = 0
    sceneGroup:insert(retourBtn)
    sceneGroup:insert(retourTxt)

    -- ─── Barre de boutons horizontal bas-gauche ──────────────────────────────
    local btnY  = display.contentHeight - 24
    local btnH  = 38
    local btnSp = 8
    local curX  = 16

    local function makeBtnPanel(w)
        local cx = curX + w / 2
        curX = curX + w + btnSp
        local g = display.newGroup()
        sceneGroup:insert(g)
        g.x, g.y = cx, btnY
        local panel = display.newRect(g, 0, 0, w, btnH)
        panel:setFillColor(unpack(C.nav))
        panel.strokeWidth = 1
        panel:setStrokeColor(C.frame[1]*0.6, C.frame[2]*0.6, C.frame[3]*0.6)
        return g, panel
    end

    local function addLabel(g, txt)
        local t = display.newText({parent=g, text=txt, x=0, y=0, font=native.systemFontBold, fontSize=14})
        t:setFillColor(unpack(C.navArrow))
        t.isHitTestable = false
        return t
    end

    -- Bouton Retour (icône maison)
    do
        local g, panel = makeBtnPanel(44)
        local roof = display.newPolygon(g, 0, -4, {-11, 6, 11, 6, 0, -8})
        roof:setFillColor(unpack(C.navArrow)); roof.isHitTestable = false
        local body = display.newRect(g, 0, 6, 16, 11)
        body:setFillColor(unpack(C.navArrow)); body.isHitTestable = false
        local door = display.newRect(g, 0, 9, 5, 5)
        door:setFillColor(unpack(C.nav)); door.isHitTestable = false
        panel:addEventListener("tap", onAbortDraw)
    end

    -- Bouton Effacer
    local erasePanel
    do
        local g, panel = makeBtnPanel(72)
        erasePanel = panel
        addLabel(g, "Effacer")
        panel:addEventListener("tap", function()
            deleteButton.updateDeleteMode(not deleteButton.isDeleteMode())
        end)
    end

    -- Bouton Soluce
    do
        local g, panel = makeBtnPanel(72)
        addLabel(g, "Soluce")
        panel:addEventListener("tap", function()
            soluceButton:dispatchEvent({name = "tap"})
        end)
    end

    -- Bouton Fin (dev)
    do
        local g, panel = makeBtnPanel(50)
        addLabel(g, "Fin")
        panel:addEventListener("tap", function()
            finishButton:dispatchEvent({name = "tap"})
        end)
    end

    -- ─── Blink bouton Effacer selon mode delete ───────────────────────────────
    local eraseHue = 0
    local eraseBlinkTimer = timer.performWithDelay(100, function()
        if deleteButton.isDeleteMode() then
            eraseHue = (eraseHue + 0.08) % 1
            local r, g, b = utils.hsvToRgb(eraseHue, 1, 1)
            erasePanel:setFillColor(r, g, b)
        else
            erasePanel:setFillColor(unpack(C.nav))
        end
    end, 0)
    scene.eraseBlinkTimer = eraseBlinkTimer
end

scene:addEventListener("create", scene)

function scene:destroy(event)
    Runtime:removeEventListener("mouse", scene.onMouseEvent)
    if scene.eraseBlinkTimer then
        timer.cancel(scene.eraseBlinkTimer)
        scene.eraseBlinkTimer = nil
    end
end

scene:addEventListener("destroy", scene)

return scene
