local composer = require("composer")
local scene = composer.newScene()

local ColorMiniDraw = require("data.colorMap")

local function loadDataMap(page)
    local moduleName = "data.drawMap" .. page
    package.loaded[moduleName] = nil
    return require(moduleName)
end

-- ─── Palette chaude / artistique ────────────────────────────────────────────
local C = {
    bg        = {0.12, 0.09, 0.07},  -- studio sombre
    frame     = {0.50, 0.34, 0.17},  -- bois doré (cadre)
    frameShad = {0.30, 0.20, 0.10},  -- ombre du cadre
    canvas    = {0.19, 0.14, 0.11},  -- toile sombre
    plaque    = {0.38, 0.26, 0.13},  -- plaque de nom
    title     = {0.98, 0.88, 0.62},  -- crème chaude
    sub       = {0.68, 0.52, 0.35},  -- ocre clair
    accent    = {0.96, 0.72, 0.24},  -- or vif
    nav       = {0.24, 0.17, 0.11},  -- panneau nav
    navArrow  = {0.94, 0.76, 0.38},  -- ambre
    easy      = {0.36, 0.80, 0.46},  -- vert peinture
    normal    = {0.92, 0.66, 0.18},  -- ocre/orange
    hard      = {0.86, 0.28, 0.28},  -- rouge brique
    empty     = {0.15, 0.11, 0.08},  -- emplacement vide
}

-- ─── Layout ──────────────────────────────────────────────────────────────────
local CARD_W   = 270
local CARD_H   = 300
local SPACING  = 16
local NUM_COLS = 3
local NUM_ROWS = 2
local FRAME_B  = 9    -- bordure cadre (côtés et haut)
local PLAQUE_H = 30   -- hauteur de la plaque de nom en bas

local gridW = NUM_COLS * CARD_W + (NUM_COLS - 1) * SPACING
local gridH = NUM_ROWS * CARD_H + (NUM_ROWS - 1) * SPACING

local pageCurrent = 1
local pageMax     = 3
local dataMap     = loadDataMap(pageCurrent)
local sceneGroup
local pageIndicator
local leftArrow, rightArrow

-- ─── Utilitaires ─────────────────────────────────────────────────────────────
local function getPuzzleBounds(grid)
    local minR, maxR = #grid, 1
    local minC, maxC = #grid[1], 1
    for r = 1, #grid do
        for c = 1, #grid[r] do
            if grid[r][c] ~= 99 then
                if r < minR then minR = r end
                if r > maxR then maxR = r end
                if c < minC then minC = c end
                if c > maxC then maxC = c end
            end
        end
    end
    return minR, minC, maxR - minR + 1, maxC - minC + 1
end

local function diffColor(d)
    if d == "Easy"   then return C.easy
    elseif d == "Normal" then return C.normal
    else return C.hard end
end

-- ─── Carte tableau encadré ───────────────────────────────────────────────────
local function drawPaintingCard(cx, cy, mapData)
    -- Ombre portée
    local shadow = display.newRect(sceneGroup, cx + 5, cy + 5, CARD_W, CARD_H)
    shadow:setFillColor(0, 0, 0, 0.55)
    shadow.isPuzzleElement = true

    -- Cadre (bois chaud)
    local frame = display.newRect(sceneGroup, cx, cy, CARD_W, CARD_H)
    frame:setFillColor(unpack(C.frame))
    frame.strokeWidth = 2
    frame:setStrokeColor(unpack(C.frameShad))
    frame.isPuzzleElement = true

    -- Biseau intérieur (effet 3D du cadre)
    local bevel = display.newRect(sceneGroup, cx, cy, CARD_W - 4, CARD_H - 4)
    bevel:setFillColor(0, 0, 0, 0.25)
    bevel.isPuzzleElement = true

    -- Toile (surface de peinture)
    local canW = CARD_W - FRAME_B * 2
    local canH = CARD_H - FRAME_B - PLAQUE_H
    local canOffY = (FRAME_B - PLAQUE_H) / 2
    local canvas = display.newRect(sceneGroup, cx, cy + canOffY, canW, canH)
    canvas:setFillColor(unpack(C.canvas))
    canvas.isPuzzleElement = true

    -- Plaque de nom (bas du cadre)
    local plaqueY = cy + CARD_H / 2 - PLAQUE_H / 2
    local plaque = display.newRect(sceneGroup, cx, plaqueY, canW, PLAQUE_H)
    plaque:setFillColor(unpack(C.plaque))
    plaque.isPuzzleElement = true

    -- Nom du dessin (sur la plaque)
    local nameLabel = display.newText({
        parent   = sceneGroup,
        text     = mapData.data.name,
        x        = cx,
        y        = plaqueY,
        font     = native.systemFontBold,
        fontSize = 14,
    })
    nameLabel:setFillColor(unpack(C.title))
    nameLabel.isPuzzleElement = true

    -- Pastille de difficulté (coin haut-droit du cadre)
    local dc = diffColor(mapData.data.difficulty)
    local dotX = cx + CARD_W / 2 - 10
    local dotY = cy - CARD_H / 2 + 10
    local dot = display.newCircle(sceneGroup, dotX, dotY, 7)
    dot:setFillColor(unpack(dc))
    dot.strokeWidth = 2
    dot:setStrokeColor(unpack(C.frameShad))
    dot.isPuzzleElement = true

    -- Aperçu du puzzle (centré dans la toile, remplit au maximum)
    local grid = mapData.grid
    local minR, minC, h, w = getPuzzleBounds(grid)
    local margin = 0.92
    local cellSize = math.min((canW * margin) / w, (canH * margin) / h)
    local ox = cx - (w * cellSize) / 2
    local oy = (cy + canOffY) - (h * cellSize) / 2

    for r = minR, minR + h - 1 do
        for c = minC, minC + w - 1 do
            local val = grid[r][c]
            if val ~= 99 then
                local color = ColorMiniDraw[val] or {1, 1, 1}
                local px = ox + (c - minC) * cellSize
                local py = oy + (r - minR) * cellSize
                local pix = display.newRect(sceneGroup, px, py, cellSize, cellSize)
                pix:setFillColor(unpack(color))
                pix.anchorX = 0
                pix.anchorY = 0
                pix.isPuzzleElement = true
            end
        end
    end

    -- Zone de tap transparente
    local hit = display.newRect(sceneGroup, cx, cy, CARD_W, CARD_H)
    hit:setFillColor(0, 0, 0, 0)
    hit.isHitTestable  = true
    hit.isPuzzleElement = true

    local selectedId  = mapData.num
    local currentPage = pageCurrent

    hit:addEventListener("tap", function()
        frame:setFillColor(0.72, 0.55, 0.28)
        plaque:setFillColor(0.72, 0.55, 0.28)
        timer.performWithDelay(180, function()
            if frame  and frame.setFillColor  then frame:setFillColor(unpack(C.frame))   end
            if plaque and plaque.setFillColor then plaque:setFillColor(unpack(C.plaque)) end
        end)
        timer.performWithDelay(220, function()
            composer.removeScene("swapScreen.selectDraw")
            composer.setVariable("selectedPuzzle", selectedId)
            composer.setVariable("selectedPage", currentPage)
            composer.gotoScene("swapScreen.draw", { effect = "crossFade", time = 400 })
        end)
    end)
end

-- ─── Emplacement vide ────────────────────────────────────────────────────────
local function drawEmptySlot(cx, cy)
    local shadow = display.newRect(sceneGroup, cx + 4, cy + 4, CARD_W, CARD_H)
    shadow:setFillColor(0, 0, 0, 0.30)
    shadow.isPuzzleElement = true

    local slot = display.newRect(sceneGroup, cx, cy, CARD_W, CARD_H)
    slot:setFillColor(unpack(C.empty))
    slot.strokeWidth = 2
    slot:setStrokeColor(C.frame[1] * 0.4, C.frame[2] * 0.4, C.frame[3] * 0.4)
    slot.isPuzzleElement = true

    -- Signe "+" discret au centre
    local arm = 22
    for _, pts in ipairs({{-arm,0, arm,0},{0,-arm, 0,arm}}) do
        local l = display.newLine(sceneGroup, cx+pts[1], cy+pts[2], cx+pts[3], cy+pts[4])
        l:setStrokeColor(C.frame[1]*0.5, C.frame[2]*0.5, C.frame[3]*0.5)
        l.strokeWidth = 3
        l.isPuzzleElement = true
    end
end

-- ─── Grille ──────────────────────────────────────────────────────────────────
local function computeOrigin()
    local topMargin = 75
    local botMargin = 44
    local avH = display.contentHeight - topMargin - botMargin
    return display.contentCenterX - gridW / 2,
           topMargin + (avH - gridH) / 2
end

local function drawGrid()
    local ox, oy = computeOrigin()
    local id = 1
    for row = 0, NUM_ROWS - 1 do
        for col = 0, NUM_COLS - 1 do
            local cx = ox + col * (CARD_W + SPACING) + CARD_W / 2
            local cy = oy + row * (CARD_H + SPACING) + CARD_H / 2
            local mapData = dataMap[id]
            if mapData then drawPaintingCard(cx, cy, mapData)
            else drawEmptySlot(cx, cy) end
            id = id + 1
        end
    end
end

local function clearGrid()
    for i = sceneGroup.numChildren, 1, -1 do
        local child = sceneGroup[i]
        if child.isPuzzleElement then display.remove(child) end
    end
end

local function updateNav()
    pageIndicator.text   = pageCurrent .. " / " .. pageMax
    leftArrow.isVisible  = pageCurrent > 1
    rightArrow.isVisible = pageCurrent < pageMax
end

-- ─── Création de scène ───────────────────────────────────────────────────────
function scene:create(event)
    sceneGroup = self.view
    pageCurrent = 1
    dataMap     = loadDataMap(pageCurrent)

    local letterbox = require("module.letterbox")
    letterbox.draw(sceneGroup)

    -- Fond chaud
    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY,
                               display.contentWidth, display.contentHeight)
    bg:setFillColor(unpack(C.bg))

    -- Ligne décorative basse du header
    local sepY = 62
    local sep = display.newRect(sceneGroup, display.contentCenterX, sepY, display.contentWidth * 0.7, 1)
    sep:setFillColor(unpack(C.accent))
    sep.alpha = 0.5

    -- Titre
    local title = display.newText({
        parent = sceneGroup, text = "SÉLECTIONNE UNE PEINTURE",
        x = display.contentCenterX, y = 36,
        font = native.systemFontBold, fontSize = 22,
    })
    title:setFillColor(unpack(C.title))

    -- Bouton retour (icône maison)
    local backGroup = display.newGroup()
    sceneGroup:insert(backGroup)
    backGroup.x = 40
    backGroup.y = 36

    local backPanel = display.newRect(backGroup, 0, 0, 44, 44)
    backPanel:setFillColor(unpack(C.nav))
    backPanel.strokeWidth = 1
    backPanel:setStrokeColor(C.frame[1]*0.6, C.frame[2]*0.6, C.frame[3]*0.6)

    -- Toit (triangle pointant vers le haut)
    local roof = display.newPolygon(backGroup, 0, -5, {-13, 7, 13, 7, 0, -9})
    roof:setFillColor(unpack(C.navArrow))
    roof.isHitTestable = false

    -- Corps
    local body = display.newRect(backGroup, 0, 6, 18, 12)
    body:setFillColor(unpack(C.navArrow))
    body.isHitTestable = false

    -- Porte
    local door = display.newRect(backGroup, 0, 10, 5, 6)
    door:setFillColor(unpack(C.nav))
    door.isHitTestable = false

    backPanel:addEventListener("tap", function()
        composer.gotoScene("swapScreen.Title", {effect = "fade", time = 400})
    end)

    -- Indicateur de page
    pageIndicator = display.newText({
        parent = sceneGroup, text = "",
        x = display.contentCenterX, y = display.contentHeight - 20,
        font = native.systemFontBold, fontSize = 20,
    })
    pageIndicator:setFillColor(unpack(C.sub))

    -- ─ Navigation droite ─
    local navW, navH, aSize = 44, 72, 13
    local navY = display.contentCenterY + 16

    rightArrow = display.newGroup()
    sceneGroup:insert(rightArrow)
    rightArrow.x = display.contentWidth - 46
    rightArrow.y = navY

    local rPanel = display.newRect(rightArrow, 0, 0, navW, navH)
    rPanel:setFillColor(unpack(C.nav))
    rPanel.strokeWidth = 1
    rPanel:setStrokeColor(C.frame[1]*0.6, C.frame[2]*0.6, C.frame[3]*0.6)

    local rArrow = display.newPolygon(rightArrow, 0, 0,
                    {-aSize*0.45, -aSize, aSize*0.55, 0, -aSize*0.45, aSize})
    rArrow:setFillColor(unpack(C.navArrow))
    rArrow.isHitTestable = false

    rPanel:addEventListener("tap", function()
        pageCurrent = pageCurrent + 1
        clearGrid(); dataMap = loadDataMap(pageCurrent); drawGrid(); updateNav()
    end)

    -- ─ Navigation gauche ─
    leftArrow = display.newGroup()
    sceneGroup:insert(leftArrow)
    leftArrow.x = 46
    leftArrow.y = navY

    local lPanel = display.newRect(leftArrow, 0, 0, navW, navH)
    lPanel:setFillColor(unpack(C.nav))
    lPanel.strokeWidth = 1
    lPanel:setStrokeColor(C.frame[1]*0.6, C.frame[2]*0.6, C.frame[3]*0.6)

    local lArrow = display.newPolygon(leftArrow, 0, 0,
                    {aSize*0.45, -aSize, -aSize*0.55, 0, aSize*0.45, aSize})
    lArrow:setFillColor(unpack(C.navArrow))
    lArrow.isHitTestable = false

    lPanel:addEventListener("tap", function()
        pageCurrent = pageCurrent - 1
        clearGrid(); dataMap = loadDataMap(pageCurrent); drawGrid(); updateNav()
    end)

    drawGrid()
    updateNav()
end

function scene:show(event)
    if event.phase == "will" and pageCurrent ~= 1 then
        pageCurrent = 1
        dataMap     = loadDataMap(pageCurrent)
        clearGrid()
        drawGrid()
        updateNav()
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
return scene
