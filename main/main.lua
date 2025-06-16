-- ГОТОВО:
-- возможность ускорять время, разная гравитацию, разные условия границ. (15.06.2025)
-- Надо сделать:
-- обводку для разных видах, отрисовку, соц сети, управление агентами, смена дня/ночи, инструменты для мутации, скрещевания, кроссинговера, разный размер агентов
-- Можно сделать:
-- слияние нескольких агентов

local config = require("assets.config")
local agentsModule = require("assets.agents")
local physics = require("physics")

-- инициализация таблиц
local time = config.time
local l = config.l
local db = config.db
local pt = config.pt
local tf = config.tf
local colors_rgb = config.colors_rgb

-- local constant = config.constant

-- local agents = agentsModule.agents
-- local createAgent = agentsModule.createAgent
-- local updateAgent = agentsModule.updateAgent
-- local crossoverGenes = agentsModule.crossoverGenes
-- local reproduce = agentsModule.reproduce
-- local gameLoop = agentsModule.gameLoop

-- local toggleButtonBackground = {}
-- toggleButtonBackground.fill ={}
-- toggleButtonBackground.fill.color1 = colors_rgb.gray1  -- серый светлый
-- toggleButtonBackground.fill.color2 = colors_rgb.brown1 -- серый темный

local display, native, transition, easing = display, native, transition, easing

local ui = {}
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local function settings()

    local align = "left"
    local buttonx = 48*db.zoom
    
    local function updateGravity()
        physics.setGravity(time.gravityX, time.gravityY)
    end

    local function updateTimeText()
        ui.timeText.text = l.coolf("Time Scale: %.2f", time.timeScale)
    end

    local function updateGravityText()
        ui.gravityText.text = l.coolf("Gravity: (%.1f, %.1f)", time.gravityX, time.gravityY)
    end

    local function updateBoundaryText()
        ui.boundaryText.text = l.coolf("Boundary Mode: %s", time.boundaryMode)
    end

    local function createButton(label, x, y, onRelease, sizeMultiplier, parentGroup)
        sizeMultiplier = sizeMultiplier or 1
        parentGroup = parentGroup or uiGroup
        local size = 16

        -- Создаем текст кнопки для измерения ширины
        local tempText = display.newText({
            text = label,
            x = 0,
            y = 0,
            font = tf.f,
            fontSize = tf.s * sizeMultiplier,
            align = align
        })

        local paddingX = size * sizeMultiplier
        local paddingY = size/2 * sizeMultiplier
        local buttonWidth = tempText.width + paddingX * 2
        local buttonHeight = tempText.height + paddingY * 2
        tempText:removeSelf()
        tempText = nil

        local cornerRadius = size * sizeMultiplier

        -- print(type(colors_rgb.green3))

        -- -- Создаем градиентный фон кнопки
        -- local gradientPaint = {
        --     type = "gradient",
        --     color1 = {colors_rgb.red},  -- ярко-зеленый
        --     color2 = {colors_rgb.green1},  -- темно-зеленый
        --     direction = align
        -- }

        local buttonBackground = display.newRoundedRect(x, y, buttonWidth, buttonHeight, cornerRadius)
        buttonBackground:setFillColor(pt.color(colors_rgb.green3))
        -- buttonBackground.fill = gradientPaint
        -- buttonBackground.fill.effect = "filter.pixelate"
        -- buttonBackground.fill.effect.numPixels = 4
        local shadow = display.newRoundedRect(x + 4, y + 4, buttonWidth, buttonHeight, cornerRadius)
        shadow:setFillColor(pt.color(colors_rgb.green1))
        shadow:toBack()
        parentGroup:insert(shadow)
        parentGroup:insert(buttonBackground)

        -- -- Создаем обводку для текста кнопки (тень)
        -- local outline = display.newText({
        --     text = label,
        --     x = x + 1,
        --     y = y + 1,
        --     font = tf.f,
        --     fontSize = (tf.s+1) * sizeMultiplier,
        --     align = align
        -- })
        -- outline:setFillColor(pt.color(colors_rgb.green1))  -- полупрозрачная черная тень
        -- parentGroup:insert(outline)

        local btn = display.newText({
            text = label,
            x = x,
            y = y,
            font = tf.f,
            fontSize = tf.s * sizeMultiplier,
            align = align
        })

        btn:setFillColor(pt.color(colors_rgb.green1))  -- светло-зеленый цвет
        parentGroup:insert(btn)

        -- Анимация нажатия кнопки с плавным изменением масштаба и цвета
        local function onTouch(event)
            if event.phase == "began" then
                transition.to(buttonBackground, {time=100, xScale=0.95, yScale=0.95, transition=easing.outQuad})
                transition.to(btn, {time=100, xScale=0.95, yScale=0.95, transition=easing.outQuad})
                transition.to(outline, {time=100, xScale=0.95, yScale=0.95, transition=easing.outQuad})
                transition.to(buttonBackground.fill, {time=100, color1={0,0.9,0,1}, color2={0,0.6,0,1}})
            elseif event.phase == "ended" or event.phase == "cancelled" then
                transition.to(buttonBackground, {time=100, xScale=1, yScale=1, transition=easing.outQuad})
                transition.to(btn, {time=100, xScale=1, yScale=1, transition=easing.outQuad})
                transition.to(outline, {time=100, xScale=1, yScale=1, transition=easing.outQuad})
                transition.to(buttonBackground.fill, {time=100, color1={0.0,0.7,0,1}, color2={0.0,0.4,0,1}})
                if event.phase == "ended" then
                    onRelease()
                end
            end
            return true
        end

        buttonBackground:addEventListener("touch", onTouch)
        btn:addEventListener("touch", onTouch)
        -- outline:addEventListener("touch", onTouch)

        return buttonBackground, btn, outline, shadow
    end

    local function createOutlinedText(text, x, y, fontSize, maxWidth, sizeMultiplier)
        sizeMultiplier = sizeMultiplier or 1
        maxWidth = maxWidth or 300  -- максимальная ширина текста по умолчанию

        local size = 4

        -- Создаем задний фон для текста (полупрозрачный прямоугольник с градиентом)
        local paddingX = size * sizeMultiplier
        local paddingY = size * sizeMultiplier

        local tempText = display.newText({
            text = text,
            x = 0,
            y = 0,
            width = maxWidth,
            font = tf.f,
            fontSize = fontSize * sizeMultiplier,
            align = align
        })
        local bgWidth = tempText.width + paddingX 
        local bgHeight = tempText.height + paddingY
        tempText:removeSelf()
        tempText = nil

        local bg = display.newRoundedRect(x, y, bgWidth, bgHeight, size * sizeMultiplier)
        -- local gradientPaint = {
        --     type = "gradient",
        --     color1 = {0, 0, 0, 0.6},
        --     color2 = {0, 0, 0, 0.3},
        --     direction = "down"
        -- }
        -- bg.fill = gradientPaint
        bg:setFillColor(0,0,0,0.4)
        uiGroup:insert(bg)

        -- -- Создаем тень для текста
        -- local shadow = display.newText({
        --     text = text,
        --     x = x + size * sizeMultiplier,
        --     y = y + size * sizeMultiplier,
        --     width = maxWidth,
        --     font = tf.f,
        --     fontSize = fontSize * sizeMultiplier,
        --     align = align
        -- })
        -- shadow:setFillColor(pt.color(colors_rgb.green2))  -- более мягкая тень
        -- uiGroup:insert(shadow)

        local mainText = display.newText({
            text = text,
            x = x,
            y = y,
            width = maxWidth,
            font = tf.f,
            fontSize = fontSize * sizeMultiplier,
            align = align
        })
        mainText:setFillColor(pt.color(colors_rgb.white))  -- белый цвет
        uiGroup:insert(mainText)

        return mainText, shadow, bg
    end

    ui.timeText, _ = createOutlinedText("", buttonx*db.zoom*2.5, 20, 18)
    updateTimeText()

    ui.timePlus = createButton("Time +", buttonx, 50 * db.zoom, function()
        time.timeScale = math.min(time.timeScale + 0.1, 5)
        updateTimeText()
    end)

    ui.timeMinus = createButton("Time -", buttonx, 100, function()
        time.timeScale = math.max(time.timeScale - 0.1, -5)
        updateTimeText()
    end)

    ui.gravityText, _ = createOutlinedText("", buttonx*db.zoom*2.5, 150, 18)
    updateGravityText()

    ui.gravityUp = createButton("Gravity Up", buttonx * 1.5, 190, function()
        time.gravityY = time.gravityY - 0.5
        updateGravity()
        updateGravityText()
    end)

    ui.gravityDown = createButton("Gravity Down", buttonx * 1.5, 230, function()
        time.gravityY = time.gravityY + 0.5
        updateGravity()
        updateGravityText()
    end)

    ui.gravityLeft = createButton("Gravity Left", buttonx * 1.5, 270, function()
        time.gravityX = time.gravityX - 0.5
        updateGravity()
        updateGravityText()
    end)

    ui.gravityRight = createButton("Gravity Right", buttonx * 1.5, 310, function()
        time.gravityX = time.gravityX + 0.5
        updateGravity()
        updateGravityText()
    end)

    ui.gravityReset = createButton("Gravity Reset", buttonx * 1.5, 350, function()
        time.gravityX = 0
        time.gravityY = 0
        updateGravity()
        updateGravityText()
    end)

    local boundaryModes = {"bounce", "wrap", "stop"}
    ui.boundaryText, _ = createOutlinedText("", buttonx *db.zoom* 2.5, 390, 18)
    uiGroup:insert(ui.boundaryText)
    updateBoundaryText()

    ui.boundaryButton = createButton("Boundary Mode", buttonx * 1.5 * db.zoom, 430, function()
        local currentIndex = 1
        for i, mode in ipairs(boundaryModes) do
            if mode == time.boundaryMode then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex + 1
        if currentIndex > #boundaryModes then currentIndex = 1 end
        time.boundaryMode = boundaryModes[currentIndex]
        updateBoundaryText()
    end)

    local agentsGroup = require("assets.agents").agentsGroup
    mainGroup:insert(agentsGroup)

    mainGroup:insert(uiGroup)

    -- Добавляем кнопку для скрытия/показа uiGroup в нижнем правом углу
    local function toggleUIVisibility()
        if uiGroup.isVisible then
            -- Анимируем скрытие
            transition.to(uiGroup, {time=300, alpha=0, onComplete=function()
                uiGroup.isVisible = false
            end})

        else
            -- Показываем и анимируем появление
            uiGroup.alpha = 0
            uiGroup.isVisible = true
            transition.to(uiGroup, {time=300, alpha=1})

        end
    end

    local buttonX = db.W - 64 * db.zoom
    local buttonY = db.H - 1.5 * tf.s
    local toggleButtonBackground, toggleButtonText, toggleButtonOutline, toggleButtonShadow = createButton("Toggle UI", buttonX, buttonY, toggleUIVisibility, 1)

    mainGroup:insert(toggleButtonShadow)
    mainGroup:insert(toggleButtonBackground)
    -- mainGroup:insert(toggleButtonOutline)
    mainGroup:insert(toggleButtonText)

    mainGroup.x = 0
    mainGroup.y = 0
end

-- physics.start()
physics.setGravity(0, 0)

settings()