-- utils.lua

local utils = {}
-- ─────────────────────────────────────────────────────────────────────────
--  DRAW TITLE SCREEN
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawTitleScreen()
    -- Gradient background
    for i = 0, screenHeight do
        local t = i / screenHeight
        local r = colors.darkBlue[1] * (1 - t) + colors.midBlue[1] * t
        local g = colors.darkBlue[2] * (1 - t) + colors.midBlue[2] * t
        local b = colors.darkBlue[3] * (1 - t) + colors.midBlue[3] * t
        love.graphics.setColor(r, g, b, 1)
        love.graphics.line(0, i, screenWidth, i)
    end

    -- Streaks
    love.graphics.setColor(colors.lightBlue[1], colors.lightBlue[2], colors.lightBlue[3], 0.1)
    love.graphics.setLineWidth(2)
    for i = 1, 5 do
        local y = screenHeight * 0.2 * i
        love.graphics.line(0, y, screenWidth, y - 50)
    end

    -- Floating particles
    for _, p in ipairs(particles) do
        love.graphics.setColor(colors.gold[1], colors.gold[2], colors.gold[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    -- “WELCOME TO”  --
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(colors.lightGold[1], colors.lightGold[2], colors.lightGold[3], 0.8)
    local welcomeText = "WELCOME TO"
    love.graphics.print(
        welcomeText,
        screenWidth/2 - subtitleFont:getWidth(welcomeText)/2,
        screenHeight/2 - 220    
    )

    -- Light rays behind title
    local cx, cy = screenWidth/2, screenHeight/2 - 100
    for _, ray in ipairs(lightRays) do
        love.graphics.setColor(colors.ember[1], colors.ember[2], colors.ember[3], ray.alpha * 0.3)
        love.graphics.setLineWidth(3)
        local ex = cx + math.cos(ray.angle + titleGlow * 0.5) * ray.length
        local ey = cy + math.sin(ray.angle + titleGlow * 0.5) * ray.length
        love.graphics.line(cx, cy, ex, ey)
    end

    -- Crown emblem
    drawCrown(cx, cy - 60)

    -- Main title “OLYMPUS CLASH”
    love.graphics.setFont(titleFont)
    local titleText = "OLYMPUS CLASH"
    local tx = screenWidth/2 - titleFont:getWidth(titleText)/2
    local ty = screenHeight/2 - 100

    -- Outer glow
    love.graphics.setColor(colors.ember[1], colors.ember[2], colors.ember[3], 0.2 + math.sin(titleGlow) * 0.1)
    for dx = -5, 5, 2 do
        for dy = -5, 5, 2 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(titleText, tx + dx, ty + dy)
            end
        end
    end

    -- Middle glow
    love.graphics.setColor(colors.gold[1], colors.gold[2], colors.gold[3], 0.4 + math.sin(titleGlow * 1.5) * 0.2)
    for dx = -2, 2 do
        for dy = -2, 2 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(titleText, tx + dx, ty + dy)
            end
        end
    end

    -- Actual title
    love.graphics.setColor(colors.lightGold)
    love.graphics.print(titleText, tx, ty)

    -- Taglines
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(colors.lightGold[1], colors.lightGold[2], colors.lightGold[3], 0.9)
    local taglines = {"FORGE YOUR DECK", "COMMAND THE GODS", "CONQUER OLYMPUS"}
    local tyY = ty + 100
    local totalW = 0
    for i, t in ipairs(taglines) do
        totalW = totalW + subtitleFont:getWidth(t)
        if i < #taglines then totalW = totalW + 80 end
    end
    local sx = screenWidth/2 - totalW/2
    for i, t in ipairs(taglines) do
        love.graphics.print(t, sx, tyY)
        sx = sx + subtitleFont:getWidth(t) + 80
        if i < #taglines then
            love.graphics.setColor(colors.gold)
            drawDiamond(sx - 40, tyY + 10, 6)
            love.graphics.setColor(colors.lightGold[1], colors.lightGold[2], colors.lightGold[3], 0.9)
        end
    end

    -- “PLAY NOW” button
    drawEpicButton(playButton)

    -- Bottom hint
    love.graphics.setFont(smallFont)
    love.graphics.setColor(colors.lightGold[1], colors.lightGold[2], colors.lightGold[3], 0.6)
    local bottomText = "New to Olympus? Press H for Help"
    love.graphics.print(
        bottomText,
        screenWidth/2 - smallFont:getWidth(bottomText)/2,
        screenHeight - 60
    )

    -- Controls hint
    love.graphics.setColor(colors.lightGold[1], colors.lightGold[2], colors.lightGold[3], 0.4)
    local ctrlText = "Press SPACE to play • ESC to quit"
    love.graphics.print(
        ctrlText,
        screenWidth/2 - smallFont:getWidth(ctrlText)/2,
        screenHeight - 30
    )
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW GAME SCREEN
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawGameScreen()
    -- Background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        backgroundImage, 0, 0, 0,
        screenWidth / backgroundImage:getWidth(),
        screenHeight / backgroundImage:getHeight()
    )

    -- 1) Left‐stacked hand
    utils.drawLeftHandStack()

    -- 2) Highlight drop zones if dragging
    if draggedCard and gamePhase == "staging" then
        for i = 1, gameSettings.locationsCount do
            local locX = boardLayout.locationsStartX + (i - 1) * cardDimensions.locationSpacing
            local locY = boardLayout.playerLocationsY
            love.graphics.setColor(unpack(colors.dropZone))
            -- Adjusted to highlight the full width of slots within a location
            love.graphics.rectangle("fill",
                locX, locY - 10, -- Start X directly at the location's base X
                cardDimensions.slotHorizontalSpacing * gameSettings.slotsPerLocation + (cardDimensions.width - cardDimensions.slotHorizontalSpacing),
                cardDimensions.height + 10
            )
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- 3) Draw 3 board locations
    for i = 1, gameSettings.locationsCount do
        local x = boardLayout.locationsStartX + (i - 1) * cardDimensions.locationSpacing
        utils.drawLocation(i, x)
        utils.drawLocationInfo(i, x) -- Always draw location name and effect
    end

    -- 4) Draw active particles
    love.graphics.setColor(1,1,1)
    for _, p in ipairs(activeParticles) do
        love.graphics.setColor(p.color)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    -- 5) Draw dragged card at mouse
    if draggedCard then
        local mx, my = love.mouse.getPosition()
        local x, y = mx - dragOffset.x, my - dragOffset.y
        local w, h = cardDimensions.width, cardDimensions.height
        love.graphics.push()
        love.graphics.translate(x + w/2, y + h/2)
        love.graphics.rotate(draggedCard.rotation)
        utils.drawCard(draggedCard.card, -w/2, -h/2, true, false, true)
        love.graphics.pop()
    end

    -- 6) UI: Mana, Points, Turn
    utils.drawManaDisplay()
    utils.drawPointsDisplay()
    utils.drawTurnInfo()

    -- 7) Submit button (in staging)
    if gamePhase == "staging" then
        utils.drawSubmitButton()
    end

    -- 8) Animate “+N” / “−N” flying to points
    if gamePhase == "animating_points" then
        local pq = pointQueue[pointIndex]
        if pq then
            local t = math.min(pq.elapsed / pq.duration, 1)
            local x = pq.startX + (pq.endX - pq.startX) * t
            local y = pq.startY + (pq.endY - pq.startY) * t
            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.scale(1.5, 1.5)
            local valStr = (pq.amount > 0) and ("+" .. pq.amount) or tostring(pq.amount)
            utils.drawNumber(0, 0, valStr)
            love.graphics.pop()
        end
    end

    -- 9) Event log
    utils.drawEventLog()

    -- 10) Hover tooltip
    utils.drawHoverTooltip()
end

-- ─────────────────────────────────────────────────────────────────────────
--  DRAW LOCATION INFO (Name and Effect)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawLocationInfo(index, x)
    local info = locationEffects[index]
    if not info then return end

    local yTop = boardLayout.opponentLocationsY - 40 
    local yBot = boardLayout.playerLocationsY + cardDimensions.height + 10 

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(colors.lightGold)

    -- Draw Name
    local nameWidth = subtitleFont:getWidth(info.name or "Unknown Location")
    love.graphics.print(info.name or "Unknown Location", x + cardDimensions.width/2 - nameWidth/2, yTop)
    love.graphics.print(info.name or "Unknown Location", x + cardDimensions.width/2 - nameWidth/2, yBot)

    -- Draw Effect (wrapped text)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(colors.white)
    local effectText = info.effect or "No effect"
    local effectLines = wrapText(effectText, cardDimensions.width, smallFont)
    for i, line in ipairs(effectLines) do
        local lineWidth = smallFont:getWidth(line)
        love.graphics.print(line, x + cardDimensions.width/2 - lineWidth/2, yTop + 20 + (i-1)*14)
        love.graphics.print(line, x + cardDimensions.width/2 - lineWidth/2, yBot + 20 + (i-1)*14)
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW LEFT‐STACKED HAND
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawLeftHandStack()
    local startX = boardLayout.handX
    local startY = boardLayout.handStartY
    for i, c in ipairs(player.hand) do
        local x = startX
        local y = startY + (i - 1) * boardLayout.handGapY
        local canAfford = (player.mana >= c.cost)
        utils.drawCard(c, x, y, true, false, canAfford)
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW ONE BOARD LOCATION (STAGING vs REVEALING)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawLocation(index, x)
    local yTop = boardLayout.opponentLocationsY
    local yBot = boardLayout.playerLocationsY

    -- Display "AI" label above opponent's slots
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(colors.white)
    local aiLabelWidth = subtitleFont:getWidth("AI")
    love.graphics.print("AI", x + cardDimensions.width/2 - aiLabelWidth/2, yTop - 80) -- Changed from -30 to -80


    -- 1) Draw Opponent’s cards in their respective slots
    for j = 1, gameSettings.slotsPerLocation do
        -- Position each card horizontally within its slot
        local cardX = x + (j - 1) * cardDimensions.slotHorizontalSpacing
        local c = opponent.locations[index][j] -- Get card at specific slot, might be nil
        if c then -- Only draw if a card exists in this slot
            if gamePhase == "revealing" and c.flipped then
                utils.drawCard(c, cardX, yTop, true, false) -- Draw face-up
            else
                utils.drawCard(nil, cardX, yTop, false, true) -- Draw face-down (back)
            end
        else
            
        end
    end

    -- Display "You" label above player's slots
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(colors.white)
    local youLabelWidth = subtitleFont:getWidth("You")
    love.graphics.print("You", x + cardDimensions.width/2 - youLabelWidth/2, yBot - 30)

    -- 2) Draw Player’s cards in their respective slots
    for j = 1, gameSettings.slotsPerLocation do
        -- Position each card horizontally within its slot
        local cardX = x + (j - 1) * cardDimensions.slotHorizontalSpacing
        local c = player.locations[index][j] -- Get card at specific slot, might be nil
        if c then -- Only draw if a card exists in this slot
            if gamePhase == "revealing" and c.flipped then
                utils.drawCard(c, cardX, yBot, true, false) -- Draw face-up
            else
                if gamePhase == "staging" then
                    utils.drawCard(c, cardX, yBot, true, false) -- Always show player's cards face-up in staging
                else
                    -- This line draws the card back, as you wanted.
                    utils.drawCard(nil, cardX, yBot, false, true)
                end
            end
        else
            -- This block is now empty, so the "black shadow cards" for empty slots are gone.
        end
    end

    -- 3) If we’re in the “revealing” phase AND every card at this location has flipped
    if gamePhase == "revealing" then
        local allFlipped = true
        -- Check both player and opponent cards in this location
        for k = 1, gameSettings.slotsPerLocation do -- Iterate over potential slots
            if player.locations[index][k] and not player.locations[index][k].flipped then allFlipped = false; break; end
            if opponent.locations[index][k] and not opponent.locations[index][k].flipped then allFlipped = false; break; end
        end

        if allFlipped then
            -- Calculate total power for display at this location
            local pP = utils.calculateLocationPower(player.locations[index], index)
            local oP = utils.calculateLocationPower(opponent.locations[index], index)
            love.graphics.setColor(colors.lightGold)
            love.graphics.setFont(smallFont)
            love.graphics.print("You: " .. pP, x - 50, yBot + 120)
            love.graphics.print("Opp: " .. oP, x - 50, yTop + 120)
        end
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW A CARD (FRONT OR BACK)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawCard(card, x, y, faceUp, isOpponent, canAfford)
    canAfford = (canAfford == nil) and true or canAfford
    local w, h = cardDimensions.width, cardDimensions.height

    -- If card is nil, or not faceUp, or isOpponent, draw the card back.
    if card == nil or (not faceUp) or isOpponent then
        if cardBackImage then
            love.graphics.setColor(1, 1, 1)
            local scaleX = w / cardBackImage:getWidth()
            local scaleY = h / cardBackImage:getHeight()
            love.graphics.draw(cardBackImage, x, y, 0, scaleX, scaleY)
        else
            love.graphics.setColor(colors.darkGold)
            love.graphics.rectangle("fill", x, y, w, h, 5, 5)
            love.graphics.setColor(colors.gold)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, w, h, 5, 5)
        end
        return -- Exit the function after drawing the back
    end

    -- If we reach here, 'card' is not nil, and we intend to draw the front.
    if card.image then
        love.graphics.setColor(1, 1, 1)
        local scaleX = w / card.image:getWidth()
        local scaleY = h / card.image:getHeight()
        love.graphics.draw(card.image, x, y, 0, scaleX, scaleY)
    else
        local bg = canAfford and colors.lightGold or {0.5, 0.5, 0.5}
        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", x, y, w, h, 5, 5)
        love.graphics.setColor(colors.bronze)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, w, h, 5, 5)

        love.graphics.setFont(smallFont)
        love.graphics.setColor(colors.darkBlue)
        -- Added nil checks using 'or ""' to ensure a string is always passed to print
        love.graphics.print(card.name or "",              x + 4, y + 4)
        love.graphics.print("Cost: " .. (card.cost or ""),   x + 4, y + 24)
        love.graphics.print("Power: " .. (card.power or ""), x + 4, y + 44)

        local lines = wrapText(card.text or "", w - 8, smallFont) -- Added nil check
        for i, line in ipairs(lines) do
            love.graphics.print(line, x + 4, y + 60 + (i - 1) * 12)
        end
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW “LARGE” CARD (CENTER or AI).  Also shows “Pts:” on reveal
-- ─────────────────────────────────────────────────────────────────────────
-- This function is no longer directly used for displaying the last played card in the center.
-- Keeping it for now in case it's used elsewhere or for future features.
function utils.drawLargeCard(card, x, y, ownerLabel, faceUp)
    local bigW, bigH = 140, 180

    -- Dark backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y - 30, bigW, bigH + 30, 6, 6)

    -- Owner text ("You" or "AI")
    love.graphics.setColor(colors.white)
    love.graphics.setFont(subtitleFont)
    love.graphics.print(ownerLabel, x + 6, y - 28)

    -- Draw the card itself, faceUp==true only when we want it revealed
    utils.drawCard(card, x, y, faceUp, false)

    -- If we're in the revealing phase and this card is flipped, show its current points
    if gamePhase == "revealing" and faceUp then
        local pts = (ownerLabel == "You") and player.points or opponent.points
        love.graphics.setFont(buttonFont)
        love.graphics.setColor(colors.gold)
        love.graphics.print("Pts: " .. pts, x + 6, y + bigH + 2)
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW “SUBMIT TURN” BUTTON
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawSubmitButton()
    local mx, my = love.mouse.getPosition()
    submitButton.hover = utils.isPointInButton(mx, my, submitButton)
    drawEpicButton(submitButton)
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW MANA DISPLAY (TOP‐LEFT)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawManaDisplay()
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(colors.white)
    love.graphics.print(
        "Mana: " .. player.mana .. "/" .. player.maxMana,
        boardLayout.manaDisplayX, boardLayout.manaDisplayY
    )
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW POINTS DISPLAY (TOP‐RIGHT)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawPointsDisplay()
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(colors.white)
    love.graphics.print(
        "Points: " .. player.points .. "  |  Opp: " .. opponent.points,
        boardLayout.pointsDisplayX, boardLayout.pointsDisplayY
    )
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW TURN INFO (CENTER‐TOP)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawTurnInfo()
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(colors.lightGold)
    local tstr = "Turn " .. currentTurn .. " - " .. gamePhase:upper()
    love.graphics.print(
        tstr,
        screenWidth/2 - subtitleFont:getWidth(tstr)/2, 16
    )
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW EVENT LOG (BOTTOM‐LEFT, last 4 entries)
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawEventLog()
    local baseX, baseY = 10, screenHeight - 100
    love.graphics.setFont(smallFont)
    for i = 1, math.min(4, #eventLog) do
        local entry = eventLog[#eventLog - i + 1]
        love.graphics.setColor(colors.white)
        love.graphics.print("• " .. entry.text, baseX, baseY - (i - 1) * 18)
    end
end


-- DRAW HOVER TOOLTIP (covers both player’s and AI’s cards)
function utils.drawTooltipForCard(card, mx, my)
    -- Added nil check at the beginning
    if not card then return end 

    local padding  = 6
    local tooltipW = 200
    local tooltipH = 90
    local tx       = mx + 14
    local ty       = my + 14

    -- Background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", tx, ty, tooltipW, tooltipH, 4, 4)

    -- Border
    love.graphics.setColor(colors.gold)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", tx, ty, tooltipW, tooltipH, 4, 4)

    -- Text
    love.graphics.setColor(colors.white)
    love.graphics.setFont(smallFont)
    -- Added nil checks using 'or ""'
    love.graphics.print(card.name or "",              tx + padding, ty + padding)
    love.graphics.print("Cost: " .. (card.cost or ""),   tx + padding, ty + 20)
    love.graphics.print("Power: " .. (card.power or ""), tx + padding, ty + 36)

    -- Wrapped effect text
    local lines = wrapText(card.text or "", tooltipW - padding * 2, smallFont) -- Added nil check
    for i, line in ipairs(lines) do
        love.graphics.print(line, tx + padding, ty + 52 + (i - 1) * 12)
    end
end

-- DRAW HOVER TOOLTIP (covers both player’s and AI’s cards)
function utils.drawHoverTooltip()
    local mx, my = love.mouse.getPosition()

    -- 1) Check the left‐stacked player hand
    local startX = boardLayout.handX
    local startY = boardLayout.handStartY
    for i, c in ipairs(player.hand) do
        local x = startX
        local y = startY + (i - 1) * boardLayout.handGapY
        if utils.isPointInRect(mx, my, x, y, cardDimensions.width, cardDimensions.height) then
            utils.drawTooltipForCard(c, mx, my)
            return
        end
    end

    -- 2) Check the player’s staged cards (on their platforms)
    for li = 1, gameSettings.locationsCount do
        local locX = boardLayout.locationsStartX + (li - 1) * cardDimensions.locationSpacing
        local locY = boardLayout.playerLocationsY
        for j = 1, gameSettings.slotsPerLocation do -- Iterate over slots
            local cardX = locX + (j - 1) * cardDimensions.slotHorizontalSpacing
            local c = player.locations[li][j] -- Get card in specific slot
            if c and utils.isPointInRect(mx, my, cardX, locY, cardDimensions.width, cardDimensions.height) then
                utils.drawTooltipForCard(c, mx, my)
                return
            end
        end
    end

    -- 3) Check the AI’s staged cards (on their platforms)
    for li = 1, gameSettings.locationsCount do
        local locX = boardLayout.locationsStartX + (li - 1) * cardDimensions.locationSpacing
        local locY = boardLayout.opponentLocationsY
        for j = 1, gameSettings.slotsPerLocation do -- Iterate over slots
            local cardX = locX + (j - 1) * cardDimensions.slotHorizontalSpacing
            local c = opponent.locations[li][j] -- Get card in specific slot
            if c and utils.isPointInRect(mx, my, cardX, locY, cardDimensions.width, cardDimensions.height) then
                -- Only show tooltip for AI cards if they are revealed (flipped)
                if c.flipped then
                    utils.drawTooltipForCard(c, mx, my)
                    return
                end
            end
        end
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW GAME OVER SCREEN
-- ─────────────────────────────────────────────────────────────────────────
function utils.drawGameOverScreen()
    -- Semi‐transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Win/Lose/Tie message
    love.graphics.setFont(titleFont)
    local msg, msgColor
    if winner == "player" then
        msg      = "VICTORY!"
        msgColor = colors.gold
    elseif winner == "opponent" then
        msg      = "DEFEAT!"
        msgColor = {1, 0.3, 0.3}
    else
        msg      = "TIE!"
        msgColor = colors.white
    end

    love.graphics.setColor(msgColor)
    love.graphics.print(
        msg,
        screenWidth/2 - titleFont:getWidth(msg)/2,
        screenHeight/2 - 100
    )

    -- Play Again button
    local playAgain = {
        x      = screenWidth/2 - 100,
        y      = screenHeight/2 + 40,
        width  = 200,
        height = 50,
        text   = "PLAY AGAIN",
        hover  = false
    }
    local mx, my = love.mouse.getPosition()
    playAgain.hover = utils.isPointInButton(mx, my, playAgain)
    drawEpicButton(playAgain)
    if love.mouse.isDown(1) and utils.isPointInButton(mx, my, playAgain) then
        startNewGame()
    end
end
-- Checks if (x,y) lies within rectangle at (rx,ry) with width w, height h
function utils.isPointInRect(x, y, rx, ry, w, h)
    return x >= rx and x <= rx + w
       and y >= ry and y <= ry + h
end

-- Similar, but for "buttons" (same logic—just renamed for clarity)
function utils.isPointInButton(x, y, btn)
    return x >= btn.x and x <= btn.x + btn.width
       and y >= btn.y and y <= btn.y + btn.height
end

-- Calculates total power of a list of cards, applying location effects
-- This function is crucial for dynamically calculating effective power
-- based on location rules. It does not permanently modify card.power.
function utils.calculateLocationPower(cards, locationIndex)
    local sum = 0
    -- Ensure cards is a table, even if empty, to avoid errors with ipairs
    cards = cards or {} 
    
    for _, c in ipairs(cards) do
        local effectivePower = c.power or 0 -- Start with card's current power, default to 0 if nil
        
        -- Apply Mount Olympus effect dynamically for power calculation
        if locationIndex == 1 and locationEffects[1] then
            effectivePower = effectivePower + 1 -- Mount Olympus: +1 Power
        end

        -- Apply Underworld effect dynamically for power calculation
        if locationIndex == 2 and locationEffects[2] then
            -- Underworld: -1 Power, but +2 if revealed
            effectivePower = effectivePower - 1
            if c.flipped then
                effectivePower = effectivePower + 2
            end
        end

        sum = sum + effectivePower
    end
    return sum
end
-- Draw a multi‐digit string (e.g. "+3", "−2") using a 0–9 sprite sheet.
-- Positions the leftmost digit so the entire string is centered at (x,y).
function utils.drawNumber(x, y, valueStr)
    local totalW = #valueStr * digitWidth
    local startX = x - totalW / 2
    for i = 1, #valueStr do
        local ch = valueStr:sub(i, i)
        local digit = tonumber(ch)
        if digit then
            local quad = numberQuads[digit]
            love.graphics.draw(blockNumbersImage, quad,
                startX + (i - 1) * digitWidth, y)
        end
    end
end



return utils