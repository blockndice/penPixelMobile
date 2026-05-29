-- module compass.lua

local compass = {}

local compteurX = 0
local compteurY = 0

local xGroup = display.newGroup()
local yGroup = display.newGroup()

-- Fonction pour générer une couleur unique en fonction d'un index
local function generateColor(index)
    local hue = (index * 47) % 360  -- 47 pour éviter des motifs trop répétitifs
    local c = 1
    local x = 1 - math.abs((hue / 60) % 2 - 1)

    local r, g, b
    if hue < 60 then r, g, b = c, x, 0
    elseif hue < 120 then r, g, b = x, c, 0
    elseif hue < 180 then r, g, b = 0, c, x
    elseif hue < 240 then r, g, b = 0, x, c
    elseif hue < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x
    end

    return {r, g, b}
end

function compass.resetCounters()
    compteurX = 0
    compteurY = 0

    for i = xGroup.numChildren, 1, -1 do
        xGroup[i]:removeSelf()
    end
    for i = yGroup.numChildren, 1, -1 do
        yGroup[i]:removeSelf()
    end
end

-- Ajoute un repère coloré à gauche de la mini-carte (une ligne par row)
function compass.randowX(x, size, space, baseY)
    compteurX = compteurX + 1
    local y = (baseY or 20) + (compteurX - 1) * space

    local color = generateColor(compteurX)
    local rect = display.newRect(x, y, size / 2, size)
    rect:setFillColor(unpack(color))
    rect.strokeWidth = 1
    rect:setStrokeColor(0, 0, 0)
    rect.anchorX, rect.anchorY = 0, 0
    xGroup:insert(rect)
end

-- Ajoute un repère coloré au-dessus de la mini-carte (une colonne par col)
function compass.randowY(y, size, space, baseX)
    compteurY = compteurY + 1
    local x = (baseX or 17) + (compteurY - 1) * space

    local color = generateColor(compteurY)
    local rect = display.newRect(x, y, size, size / 2)
    rect:setFillColor(unpack(color))
    rect.strokeWidth = 1
    rect:setStrokeColor(0, 0, 0)
    rect.anchorX, rect.anchorY = 0, 0
    yGroup:insert(rect)
end

-- Ajoute un pixel coloré verticalement (pour les lignes) - VERSION DYNAMIQUE
function compass.randowX2(i, gridOffsetY, x, size, space, decalageHaut)
    -- Décalage vertical ajustable (paramètre optionnel, défaut 0)
    decalageHaut = decalageHaut or 0

    local y = gridOffsetY + (i - 1) * space + (space - size) / 2 - decalageHaut
    local color = generateColor(i)

    local rect = display.newRect(x, y, size / 2, size)
    rect:setFillColor(unpack(color))
    rect.strokeWidth = 1
    rect:setStrokeColor(0, 0, 0)

    rect.anchorX, rect.anchorY = 0, 0
    xGroup:insert(rect)
end

-- Ajoute un pixel coloré horizontalement (pour les colonnes) - VERSION DYNAMIQUE
function compass.randowY2(j, gridOffsetX, y, size, space, decalageGauche)
    -- Décalage horizontal ajustable (paramètre optionnel, défaut 0)
    decalageGauche = decalageGauche or 0

    local x = gridOffsetX + (j - 1) * space + (space - size) / 2 - decalageGauche
    local color = generateColor(j)

    local rect = display.newRect(x, y, size, size / 2)
    rect:setFillColor(unpack(color))
    rect.strokeWidth = 1
    rect:setStrokeColor(0, 0, 0)

    rect.anchorX, rect.anchorY = 0, 0
    yGroup:insert(rect)
end

return compass