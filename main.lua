-- main.lua
-- Olympian Draw - A Greek Mythology Card Game (with digit‐animation to points)

CardPrototype = require("CardPrototype")
cardList      = require("cards")
local utils   = require("utils")
Audio         = require("audio")



-- ─────────────────────────────────────────────────────────────────────────
--  LOVE.LOAD
-- ─────────────────────────────────────────────────────────────────────────
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    Audio:load()
    Audio:playBGM()
    -- ─────────────────────────────────────────────────────────────────────
    -- WINDOW SIZE: 1280×800
    -- ─────────────────────────────────────────────────────────────────────
    love.window.setMode(1280, 800)
    love.window.setTitle("Olympian Draw")
    screenWidth  = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    -- ─────────────────────────────────────────────────────────────────────
    -- LOAD BACKGROUND IMAGE
    -- ─────────────────────────────────────────────────────────────────────
    backgroundImage = love.graphics.newImage("assets/background.jpg")
    cardBackImage = love.graphics.newImage("assets/cards/back.png")

    -- ─────────────────────────────────────────────────────────────────────
    -- LOAD DIGIT SPRITE SHEET (0–9)
    -- ─────────────────────────────────────────────────────────────────────
    blockNumbersImage = love.graphics.newImage("assets/block_numbers_gb_01.png")
    local sheetW, sheetH = blockNumbersImage:getDimensions()
    digitWidth  = sheetW / 10
    digitHeight = sheetH
    numberQuads = {}
    for d = 0, 9 do
        numberQuads[d] = love.graphics.newQuad(
            d * digitWidth, 0,
            digitWidth, digitHeight,
            sheetW, sheetH
        )
    end

    -- ─────────────────────────────────────────────────────────────────────
    -- CARD DIMENSIONS
    -- ─────────────────────────────────────────────────────────────────────
    cardDimensions = {
        width           = 150,
        height          = 150,
        locationSpacing = 250, 
        cardSlotSpacing = 30, 
        slotHorizontalSpacing = 35 
    }

    -- ─────────────────────────────────────────────────────────────────────
    -- LAYOUT POSITIONS
    -- ─────────────────────────────────────────────────────────────────────
    boardLayout = {
        handX             = 10,
        handStartY        = 40,
        handGapY          = 120,

        playerLocationsY   = screenHeight - 350,
        opponentLocationsY = 150,
        locationsStartX    = screenWidth/2 - cardDimensions.locationSpacing * 1.2,


        manaDisplayX      = 20,
        manaDisplayY      = 20,
        pointsDisplayX    = screenWidth - 320,
        pointsDisplayY    = 20
    }

    -- ─────────────────────────────────────────────────────────────────────
    -- GAME SETTINGS
    -- ─────────────────────────────────────────────────────────────────────
    gameSettings = {
        targetPoints     = 15,
        maxHandSize      = 7,
        startingHandSize = 3,
        deckSize         = 20,
        locationsCount   = 3,
        slotsPerLocation = 4
    }

    -- Player data
    player = {
        deck      = {},
        hand      = {},
        discard   = {},
        mana      = 1,
        maxMana   = 1,
        manaNext  = nil,
        points    = 0,
        locations = {{}, {}, {}}
    }

    -- Opponent data
    opponent = {
        deck      = {},
        hand      = {},
        discard   = {},
        mana      = 1,
        maxMana   = 1,
        points    = 0,
        locations = {{}, {}, {}}
    }

    -- Phase / Turn / Queues
    currentTurn       = 1
    gamePhase         = "staging"
    playerSubmitted   = false
    opponentSubmitted = false

    revealQueue     = {}
    revealIndex     = 1
    revealTimer     = 0

    pointQueue      = {}
    pointIndex      = 1

    winner          = nil

    draggedCard     = nil
    dragOffset      = { x = 0, y = 0 }

    eventLog        = {}

    gameState       = "title"
    
    -- Particles
    activeParticles = {}
    particleGravity = 80

    -- ─────────────────────────────────────────────────────────────────────
    -- FONTS
    -- ─────────────────────────────────────────────────────────────────────
    titleFont    = love.graphics.newFont(64)
    subtitleFont = love.graphics.newFont(18)
    buttonFont   = love.graphics.newFont(22)
    smallFont    = love.graphics.newFont(14)

    -- ─────────────────────────────────────────────────────────────────────
    -- TITLE SCREEN ANIMATIONS (GLOW + PARTICLES)
    -- ─────────────────────────────────────────────────────────────────────
    titleGlow     = 0
    particleTimer = 0
    lightRays     = {}
    for i = 1, 8 do
        table.insert(lightRays, {
            angle  = (i - 1) * (math.pi * 2 / 8),
            length = 80 + math.random(40),
            alpha  = 0.3 + math.random() * 0.4
        })
    end

    particles = {}
    for i = 1, 20 do
        table.insert(particles, {
            x         = math.random(screenWidth),
            y         = math.random(screenHeight),
            speed     = 10 + math.random(15),
            size      = 1 + math.random(2),
            alpha     = 0.3 + math.random() * 0.4,
            direction = math.random() * math.pi * 2
        })
    end

    -- ─────────────────────────────────────────────────────────────────────
    -- PLAY BUTTON (TITLE)
    -- ─────────────────────────────────────────────────────────────────────
    playButton = {
        x      = screenWidth/2 - 120,
        y      = screenHeight/2 + 100,
        width  = 240,
        height = 60,
        text   = "PLAY NOW",
        hover  = false
    }

    -- ─────────────────────────────────────────────────────────────────────
    -- SUBMIT BUTTON (IN‐GAME)
    -- ─────────────────────────────────────────────────────────────────────
    submitButton = {
        x      = screenWidth - 220,
        y      = screenHeight - 80,
        width  = 180,
        height = 40,
        text   = "SUBMIT TURN",
        hover  = false
    }

    -- ─────────────────────────────────────────────────────────────────────
    -- UI COLORS
    -- ─────────────────────────────────────────────────────────────────────
    colors = {
        gold      = {1, 0.84, 0.2},
        darkGold  = {0.8, 0.6, 0.1},
        bronze    = {0.8, 0.5, 0.2},
        darkBlue  = {0.05, 0.1, 0.2},
        midBlue   = {0.1, 0.2, 0.35},
        lightBlue = {0.2, 0.3, 0.5},
        white     = {1, 1, 1},
        lightGold = {1, 0.9, 0.6},
        ember     = {1, 0.6, 0.2},
        dropZone  = {0.2, 0.8, 0.2, 0.3}
    }
    
    uiDirtyFlags = {
      handChanged = true,
      boardChanged = true
    }
    
   
    locationEffects = {
        [1] = {
            name = "Mount Olympus",
            effect = "Cards here gain +1 Power.",
        },
        [2] = {
            name = "Underworld",
            effect = "Cards here lose 1 Power but gain +2 if revealed.",
        },
        [3] = {
            name = "River Styx",
            effect = "When played here, draw a card.",
            onPlay = function(owner)
                if owner == "player" then
                    drawOneCard(player)
                else
                    drawOneCard(opponent)
                end
            end
        }
    }


end


-- ─────────────────────────────────────────────────────────────────────────
--  DEEP‐COPY A CARD TEMPLATE
-- ─────────────────────────────────────────────────────────────────────────
function createCardCopy(template)
    local card = {}
    for k, v in pairs(template) do
        if type(v) == "function" then
            card[k] = v  
        elseif type(v) == "table" then
        
            card[k] = {}
            for tk, tv in pairs(v) do
                card[k][tk] = tv
            end
        else
            card[k] = v
        end
    end
    card.id = math.random(1000000)
    card.flipped = false
    card.basePower = template.power  
    return card
end

function resetCardPowers()
    for li = 1, gameSettings.locationsCount do
        for _, c in ipairs(player.locations[li]) do
            if c.basePower then
                c.power = c.basePower
            end
        end
        for _, c in ipairs(opponent.locations[li]) do
            if c.basePower then
                c.power = c.basePower
            end
        end
    end
    
    for _, c in ipairs(player.hand) do
        if c.basePower then
            c.power = c.basePower
        end
    end
    for _, c in ipairs(opponent.hand) do
        if c.basePower then
            c.power = c.basePower
        end
    end
end

function executeRevealEffects()
    for _, step in ipairs(revealQueue) do
        local card = step.card
        local locationIndex = step.location
        local owner = step.owner

        -- Set proper context
        if owner == "player" then
            _G.currentPlayer = player
            _G.currentOpponent = opponent
        else
            _G.currentPlayer = opponent
            _G.currentOpponent = player
        end

        if card.onReveal then
            table.insert(eventLog, {
                text = (card.name or "Unnamed Card") .. " onReveal → " .. (card.text or "No text"),
                timer = 3
            })
            card:onReveal(locationIndex)
        end

        _G.currentPlayer = nil
        _G.currentOpponent = nil
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  WRAP‐TEXT HELPER (for card text)
-- ─────────────────────────────────────────────────────────────────────────
function wrapText(text, maxWidth, font)
    local words = {}
    for w in text:gmatch("%S+") do table.insert(words, w) end
    local lines = {}
    local cur   = ""
    for _, w in ipairs(words) do
        local test = (#cur == 0) and w or (cur .. " " .. w)
        if font:getWidth(test) <= maxWidth then
            cur = test
        else
            if #cur > 0 then table.insert(lines, cur) end
            cur = w
        end
    end
    if #cur > 0 then table.insert(lines, cur) end
    return lines
end


-- ─────────────────────────────────────────────────────────────────────────
--  PARTICLE SYSTEM
-- ─────────────────────────────────────────────────────────────────────────
function spawnParticles(x, y, count)
    for i = 1, count do
        local angle = math.random() * 2 * math.pi
        local speed = 50 + math.random(100)
        table.insert(activeParticles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            lifespan = 0.5 + math.random() * 0.5,
            size = 2 + math.random(2),
            color = colors.gold
        })
    end
end

-- ─────────────────────────────────────────────────────────────────────────
--  START A NEW GAME (reset everything)
-- ─────────────────────────────────────────────────────────────────────────
function startNewGame()
    currentTurn       = 1
    gamePhase         = "staging"
    playerSubmitted   = false
    opponentSubmitted = false

    revealQueue       = {}
    revealIndex       = 1
    revealTimer       = 0

    pointQueue        = {}
    pointIndex        = 1

    winner            = nil
    eventLog          = {}
    activeParticles   = {}

    -- Reset player/opponent data
    player.deck       = {}
    opponent.deck     = {}
    player.hand       = {}
    opponent.hand     = {}
    player.discard    = {}
    opponent.discard  = {}
    player.points     = 0
    opponent.points   = 0
    player.locations  = {{}, {}, {}}
    opponent.locations= {{}, {}, {}}
    player.mana       = 1
    player.maxMana    = 1
    player.manaNext   = nil
    opponent.mana     = 1
    opponent.maxMana  = 1

    -- Build & shuffle decks
    createDecks()
    dealStartingHands()

    gameState = "game"
end


-- ─────────────────────────────────────────────────────────────────────────
--  BUILD & SHUFFLE DECKS
-- ─────────────────────────────────────────────────────────────────────────
function createDecks()
    local names = {
        "Zeus", "Ares", "Hera", "Apollo", "Demeter",
        "Hades", "Artemis", "Cyclops", "Pegasus", "WoodenCow"
    }
    player.deck       = {}
    opponent.deck     = {}
    for _, name in ipairs(names) do
        for i = 1, 2 do
            table.insert(player.deck,   createCardCopy(cardList[name]))
            table.insert(opponent.deck, createCardCopy(cardList[name]))
        end
    end
    shuffleDeck(player.deck)
    shuffleDeck(opponent.deck)
end

function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DEAL STARTING HANDS (Strictly 3 cards, no extra draw)
-- ─────────────────────────────────────────────────────────────────────────
function dealStartingHands()
    player.hand   = {}
    opponent.hand = {}
    for i = 1, gameSettings.startingHandSize do 
        if #player.deck > 0 then
            table.insert(player.hand, table.remove(player.deck, 1))
        end
        if #opponent.deck > 0 then
            table.insert(opponent.hand, table.remove(opponent.deck, 1))
        end
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  LOVE.UPDATE
-- ─────────────────────────────────────────────────────────────────────────
function love.update(dt)
    for i = #activeParticles, 1, -1 do
        local p = activeParticles[i]
        p.lifespan = p.lifespan - dt
        if p.lifespan <= 0 then
            table.remove(activeParticles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + particleGravity * dt 
        end
    end

    if gameState == "title" then
        titleGlow     = titleGlow + dt * 2
        particleTimer = particleTimer + dt
        for _, p in ipairs(particles) do
            p.x = p.x + math.cos(p.direction) * p.speed * dt
            p.y = p.y + math.sin(p.direction) * p.speed * dt
            if p.x < 0       then p.x = screenWidth  end
            if p.x > screenWidth  then p.x = 0        end
            if p.y < 0       then p.y = screenHeight end
            if p.y > screenHeight then p.y = 0        end
            p.alpha = 0.2 + math.sin(particleTimer * 2 + p.x * 0.01) * 0.3
        end

        -- Hover for “PLAY NOW”
        local mx, my = love.mouse.getPosition()
        playButton.hover = utils.isPointInButton(mx, my, playButton)

    elseif gameState == "game" then
        -- Update dragged card physics
        if draggedCard then
            -- Smoothly interpolate rotation back to neutral
            draggedCard.targetRotation = draggedCard.targetRotation * (1 - 8 * dt)
            -- Apply rotation based on target
            draggedCard.rotation = draggedCard.rotation + (draggedCard.targetRotation - draggedCard.rotation) * 15 * dt
        end

        if gamePhase == "staging" then
            -- Hover for “SUBMIT TURN”
            local mx, my = love.mouse.getPosition()
            submitButton.hover = utils.isPointInButton(mx, my, submitButton)

        elseif gamePhase == "show_ai" then
            -- Pause so player sees AI’s last‐played card face‐down
            aiTimer = aiTimer - dt
            if aiTimer <= 0 then
                -- After the pause, move into revealing
                gamePhase   = "revealing"
                revealIndex = 1
                revealTimer = 0.5
            end

        elseif gamePhase == "revealing" then
          revealTimer = revealTimer - dt
          if revealIndex <= #revealQueue and revealTimer <= 0 then
              local step = revealQueue[revealIndex]
              local owner, card, loc = step.owner, step.card, step.location

              -- Flip card only, defer onReveal
              card.flipped = true

              local who = (owner == "player") and "You" or "AI"
              table.insert(eventLog, {
                  text = who .. " reveals " .. (card.name or "Unnamed Card") .. "!",
                  timer = 3
              })

              revealIndex = revealIndex + 1
              revealTimer = 2
          end

          if revealIndex > #revealQueue and revealTimer <= 0 then
              executeRevealEffects()
              queuePointAnimations()

              if #pointQueue == 0 then
                  if checkWinCondition() then
                      gameState = "gameover"
                  else
                      nextTurn()
                  end
              else
                  gamePhase = "animating_points"
                  pointIndex = 1
              end
          end

        elseif gamePhase == "animating_points" then
            -- Animate each “+N” or “−N” flying from battlefield to the score area
            local pq = pointQueue[pointIndex]
            if pq then
                pq.elapsed = pq.elapsed + dt
                if pq.elapsed >= pq.duration then
                    -- Once the animation finishes, actually add to points
                    if pq.owner == "player" then
                        player.points = player.points + pq.amount
                    else
                        opponent.points = opponent.points + pq.amount
                    end

                    pointIndex = pointIndex + 1
                    if pointIndex > #pointQueue then
                        -- After all point animations, check for win or next turn
                        if checkWinCondition() then
                            gameState = "gameover"
                        else
                            nextTurn()
                        end
                    end
                end
            end
        end
    end

    -- Fade out old event‐log entries
    for i = #eventLog, 1, -1 do
        eventLog[i].timer = eventLog[i].timer - dt
        if eventLog[i].timer <= 0 then
            table.remove(eventLog, i)
        end
    end
end



-- ─────────────────────────────────────────────────────────────────────────
--  LOVE.DRAW
-- ─────────────────────────────────────────────────────────────────────────
function love.draw()
    if gameState == "title" then
        utils.drawTitleScreen()
    elseif gameState == "game" then
        utils.drawGameScreen()
    elseif gameState == "gameover" then
        utils.drawGameOverScreen()
    end
end



-- ─────────────────────────────────────────────────────────────────────────
--  MOUSE & KEY HANDLERS
-- ─────────────────────────────────────────────────────────────────────────
function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    if gameState == "title" then
        if utils.isPointInButton(x, y, playButton) then
            startNewGame()
        end

    elseif gameState == "game" then
        if gamePhase == "staging" then
            -- If “SUBMIT TURN” clicked
            if utils.isPointInButton(x, y, submitButton) then
                submitPlayerTurn()
                return
            end

            local startX = boardLayout.handX
            local startY = boardLayout.handStartY
            for i, c in ipairs(player.hand) do
                local cardX = startX
                local cardY = startY + (i - 1) * boardLayout.handGapY
                if utils.isPointInRect(x, y, cardX, cardY, cardDimensions.width, cardDimensions.height) then
                    if player.mana >= c.cost then
                        draggedCard = {
                            card = c,
                            handIndex = i,
                            rotation = 0, 
                            targetRotation = 0 
                        }
                        dragOffset.x = x - cardX
                        dragOffset.y = y - cardY
                    end
                    break
                end
            end
        end

    elseif gameState == "gameover" then
        -- Handled in drawGameOverScreen
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 then return end
    if gameState == "game" and draggedCard and gamePhase == "staging" then
        local cardPlaced = false
        for i = 1, gameSettings.locationsCount do
            -- Calculate individual slot drop zones within each location
            local locX = boardLayout.locationsStartX + (i - 1) * cardDimensions.locationSpacing
            local locY = boardLayout.playerLocationsY
            
            -- Adjusted to check each slot individually within the location's broader drop zone
            for j = 1, gameSettings.slotsPerLocation do
                local slotX = locX + (j - 1) * cardDimensions.slotHorizontalSpacing
                -- Check if the mouse is over this specific slot
                if utils.isPointInRect(x, y, slotX, locY, cardDimensions.width, cardDimensions.height) then
                    if not player.locations[i][j] then -- Check if slot is empty
                        local c = draggedCard.card
                        table.remove(player.hand, draggedCard.handIndex)
                        player.locations[i][j] = c -- Place card directly into the slot
                        player.mana = player.mana - c.cost
                        
                        -- Spawn particles on successful play
                        spawnParticles(slotX + cardDimensions.width / 2, locY + cardDimensions.height / 2, 30)

                        -- Trigger onOtherCardPlayedHere effects for existing cards at this location
                        for _, other in ipairs(player.locations[i]) do
                            if other and other ~= c and other.onOtherCardPlayedHere then -- Check if other is not nil
                                table.insert(eventLog, {
                                    text = (other.name or "Unnamed Card") .. " onOtherCardPlayedHere → " .. (other.text or "No text"),
                                    timer = 3
                                })
                                other:onOtherCardPlayedHere(c, i)
                            end
                        end

                        -- Trigger onPlay effect of the newly played card if it exists
                        table.insert(eventLog, {
                            text  = "You played " .. (c.name or "Unnamed Card") .. " → " .. (c.text or "No text"),
                            timer = 3
                        })
                        if c.onPlay then
                            table.insert(eventLog, {
                                text  = (c.name or "Unnamed Card") .. " onPlay Triggered!",
                                timer = 3
                            })
                            c:onPlay(i)
                        end
                        
                        cardPlaced = true
                        uiDirtyFlags.handChanged = true
                        uiDirtyFlags.boardChanged = true
                        break -- Card was successfully placed in this slot, stop checking other slots/locations
                    end
                end
            end
            if cardPlaced then break end -- If placed, stop checking other locations
        end
        draggedCard = nil -- Reset draggedCard regardless of drop success
    end
end

function love.mousemoved(x, y, dx, dy)
    if draggedCard then
        -- Update target rotation based on horizontal mouse movement for a sway effect
        draggedCard.targetRotation = math.max(-0.4, math.min(0.4, dx * 0.03))
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "game" then
            gameState = "title"
        else
            love.event.quit()
        end
    elseif key == "space" and gameState == "title" then
        startNewGame()
    elseif key == "h" and gameState == "title" then
        print("Help screen would go here!")
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  GAME LOGIC FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────

-- Coin flip logic for tie-breaking
function flipCoin()
    if math.random(0, 1) == 1 then
        return "player" -- Heads
    else
        return "opponent" -- Tails
    end
end

-- Called when player clicks “SUBMIT TURN”
function submitPlayerTurn()
    playerSubmitted = true
    gamePhase       = "show_ai"
    aiTimer         = 1.0  -- seconds to pause before revealing

    -- Let AI play now (so lastAICard is set immediately)
    playAITurn()

    -- Build revealQueue based on location power, with coin flip for ties
    revealQueue = {}
    for li = 1, gameSettings.locationsCount do
        -- Calculate initial powers for reveal order determination
        local playerPower = utils.calculateLocationPower(player.locations[li], li)
        local opponentPower = utils.calculateLocationPower(opponent.locations[li], li)

        local firstRevealingOwner = nil
        local secondRevealingOwner = nil

        if playerPower > opponentPower then
            firstRevealingOwner = "player"
            secondRevealingOwner = "opponent"
        elseif opponentPower > playerPower then
            firstRevealingOwner = "opponent"
            secondRevealingOwner = "player"
        else -- It's a tie for reveal order at this location
            firstRevealingOwner = flipCoin()
            if firstRevealingOwner == "player" then
                secondRevealingOwner = "opponent"
            else
                secondRevealingOwner = "player"
            end
            table.insert(eventLog, {
                text = "Location " .. li .. " is a power tie! " .. firstRevealingOwner .. " wins the coin flip to reveal first.",
                timer = 3
            })
        end

        -- Queue cards for the first revealing owner
        local firstOwnerCards = (firstRevealingOwner == "player") and player.locations[li] or opponent.locations[li]
        for j = 1, gameSettings.slotsPerLocation do -- Iterate through slots
            local c = firstOwnerCards[j]
            if c then
                table.insert(revealQueue, {
                    owner    = firstRevealingOwner,
                    card     = c,
                    location = li
                })
            end
        end

        -- Queue cards for the second revealing owner
        local secondOwnerCards = (secondRevealingOwner == "player") and player.locations[li] or opponent.locations[li]
        for j = 1, gameSettings.slotsPerLocation do -- Iterate through slots
            local c = secondOwnerCards[j]
            if c then
                table.insert(revealQueue, {
                    owner    = secondRevealingOwner,
                    card     = c,
                    location = li
                })
            end
        end
    end
end

-- AI plays random affordable card into any open location
function playAITurn()
    opponentSubmitted = true
    local tries = 0
    while #opponent.hand > 0 and tries < 10 do -- Limit tries to prevent infinite loops if no affordable cards/slots
        tries = tries + 1
        local affordableCards = {}
        for _, c in ipairs(opponent.hand) do
            if opponent.mana >= c.cost then
                table.insert(affordableCards, c)
            end
        end

        if #affordableCards == 0 then break end -- No affordable cards, AI stops playing

        local c = affordableCards[math.random(#affordableCards)]
        
        local availableSlots = {}
        for li = 1, gameSettings.locationsCount do
            for j = 1, gameSettings.slotsPerLocation do
                if not opponent.locations[li][j] then -- Check if slot is empty
                    table.insert(availableSlots, {location = li, slot = j})
                end
            end
        end

        if #availableSlots == 0 then break end -- No available slots, AI stops playing

        local chosenSlot = availableSlots[math.random(#availableSlots)]
        local li = chosenSlot.location
        local slot_j = chosenSlot.slot

        -- Remove card from hand
        for k, v in ipairs(opponent.hand) do
            if v == c then
                table.remove(opponent.hand, k)
                break
            end
        end

        -- Place card in location slot
        opponent.locations[li][slot_j] = c
        opponent.mana = opponent.mana - c.cost
        
        -- Spawn particles for AI play
        local locX = boardLayout.locationsStartX + (li - 1) * cardDimensions.locationSpacing
        local cardX = locX + (slot_j - 1) * cardDimensions.slotHorizontalSpacing
        spawnParticles(cardX + cardDimensions.width / 2, boardLayout.opponentLocationsY + cardDimensions.height / 2, 30)

        -- Trigger onPlay effect of the newly played card if it exists
        if c.onPlay then
            table.insert(eventLog, {
                text  = (c.name or "Unnamed Card") .. " AI onPlay Triggered!",
                timer = 3
            })
            c:onPlay(li)
        end

        -- Trigger onOtherCardPlayedHere effects for existing cards at this location for AI
        for _, other in ipairs(opponent.locations[li]) do
            if other and other ~= c and other.onOtherCardPlayedHere then -- Check if other is not nil
                 table.insert(eventLog, {
                    text = (other.name or "Unnamed Card") .. " AI onOtherCardPlayedHere Triggered!",
                    timer = 3
                })
                other:onOtherCardPlayedHere(c, li)
            end
        end
    end
end

-- Once all reveals are done, build a queue of point animations
function queuePointAnimations()
    pointQueue = {}

    for li = 1, gameSettings.locationsCount do
        -- Calculate total power for player and opponent at this location,
        -- using utils.calculateLocationPower to apply dynamic location effects.
        local playerLocationTotalPower = 0
        for j = 1, gameSettings.slotsPerLocation do
            local c = player.locations[li][j]
            if c then
                playerLocationTotalPower = playerLocationTotalPower + utils.calculateLocationPower({c}, li)
            end
        end

        local opponentLocationTotalPower = 0
        for j = 1, gameSettings.slotsPerLocation do
            local c = opponent.locations[li][j]
            if c then
                opponentLocationTotalPower = opponentLocationTotalPower + utils.calculateLocationPower({c}, li)
            end
        end
        
        -- Debugging prints for clarity
        print("---- Location", li, "----")
        print("Player effective power at location " .. li .. ":", playerLocationTotalPower)
        print("Opponent effective power at location " .. li .. ":", opponentLocationTotalPower)


        -- Determine winner and point difference
        local pointDiff, winner = 0, nil
        if playerLocationTotalPower > opponentLocationTotalPower then
            pointDiff = playerLocationTotalPower - opponentLocationTotalPower
            winner = "player"
        elseif opponentLocationTotalPower > playerLocationTotalPower then
            pointDiff = opponentLocationTotalPower - playerLocationTotalPower
            winner = "opponent"
        else
            -- If location is tied for points, determine winner via coin flip for point allocation
            winner = flipCoin()
            table.insert(eventLog, {
                text = "Point Tie at Location " .. li .. "! " .. winner .. " wins the coin flip for points.",
                timer = 3
            })
            -- Point difference is 0 in a tie, but we still assign winner for logging/animation
            -- If you want points for winning a tied location, you would set pointDiff to something like 1 here.
        end

        -- Show who won and by how much
        if winner then
            table.insert(eventLog, {
                text = winner .. " wins Location " .. li .. " by " .. pointDiff .. " power!",
                timer = 3
            })
            print("→ " .. winner .. " wins by", pointDiff)
        else
            table.insert(eventLog, {
                text = "Tie at Location " .. li .. "!",
                timer = 3
            })
            print("→ Tie at this location")
        end

        -- Create point animation (only if there's a difference, or if you decide to give 1 point for a tie-win)
        if winner and pointDiff > 0 then -- Only animate if points are actually gained
            local startX = boardLayout.locationsStartX + (li - 1) * cardDimensions.locationSpacing + cardDimensions.width / 2
            local startY = (boardLayout.playerLocationsY + boardLayout.opponentLocationsY) / 2
            local endX, endY = 0, 0

            if winner == "player" then
                endX = boardLayout.pointsDisplayX + 30
                endY = boardLayout.pointsDisplayY + 10
            else
                endX = boardLayout.pointsDisplayX + 150
                endY = boardLayout.pointsDisplayY + 10
            end

            table.insert(pointQueue, {
                amount   = pointDiff,
                owner    = winner,
                startX   = startX,
                startY   = startY,
                endX     = endX,
                endY     = endY,
                elapsed  = 0,
                duration = 1.0
            })
        end
    end
end


function updateRevealingPhase(dt)
    revealTimer = revealTimer - dt
    if revealIndex <= #revealQueue and revealTimer <= 0 then
        local step = revealQueue[revealIndex]
        local owner, card, loc = step.owner, step.card, step.location

        -- Flip that one card face‐up
        card.flipped = true

        -- Set proper context
        if owner == "player" then
            _G.currentPlayer = player
            _G.currentOpponent = opponent
        else
            _G.currentPlayer = opponent
            _G.currentOpponent = player
        end

        -- Log reveal
        local who = (owner == "player") and "You" or "AI"
        table.insert(eventLog, {
            text = who .. " reveals " .. (card.name or "Unnamed Card") .. "!",
            timer = 3
        })

        -- Execute onReveal effect (Text of card effect shown here in log)
        if card.onReveal then
            table.insert(eventLog, {
                text = (card.name or "Unnamed Card") .. " onReveal: " .. (card.text or "No text"),
                timer = 3
            })
            card:onReveal(loc)
        end

        -- Clear context
        _G.currentPlayer = nil
        _G.currentOpponent = nil

        revealIndex = revealIndex + 1
        revealTimer = 2
    end
end


-- Check if either reached targetPoints; set `winner` accordingly
function checkWinCondition()
    if player.points >= gameSettings.targetPoints or opponent.points >= gameSettings.targetPoints then
        if player.points > opponent.points then
            winner = "player"
        elseif opponent.points > player.points then
            winner = "opponent"
        else
            winner = "tie"
        end
        return true
    end
    return false
end

-- Advance to next turn (or game over)
function nextTurn()
    currentTurn = currentTurn + 1
    resetCardPowers() -- Reset power values on cards to base before next turn's calculations

    player.maxMana = math.min(currentTurn, 10)
    player.mana = player.manaNext or player.maxMana -- Use manaNext if set
    player.manaNext = nil -- Reset manaNext for next turn

    opponent.maxMana = math.min(currentTurn, 10)
    opponent.mana = opponent.maxMana

    drawOneCard(player)
    drawOneCard(opponent)

    playerSubmitted = false
    opponentSubmitted = false
    gamePhase = "staging"

    revealQueue = {}
    revealIndex = 1
    revealTimer = 0

    pointQueue = {}
    pointIndex = 1

    -- Move cards from locations to discard pile and trigger onDiscard
    for li = 1, gameSettings.locationsCount do
        -- Iterate through slots to ensure all cards are processed, even if sparse
        for j = 1, gameSettings.slotsPerLocation do
            local card = player.locations[li][j]
            if card then
                card.flipped = false -- Reset flipped state
                table.insert(player.discard, card)
                if card.onDiscard then
                    table.insert(eventLog, {
                        text = (card.name or "Unnamed Card") .. " was discarded, onDiscard triggered!",
                        timer = 3
                    })
                    card:onDiscard()
                end
                player.locations[li][j] = nil -- Clear the slot
            end
        end
        for j = 1, gameSettings.slotsPerLocation do
            local card = opponent.locations[li][j]
            if card then
                card.flipped = false -- Reset flipped state
                table.insert(opponent.discard, card)
                if card.onDiscard then
                    table.insert(eventLog, {
                        text = (card.name or "Unnamed Card") .. " was discarded, onDiscard triggered!",
                        timer = 3
                    })
                    card:onDiscard()
                end
                opponent.locations[li][j] = nil -- Clear the slot
            end
        end
        -- Ensure entire location table is empty after clearing slots
        player.locations[li] = {}
        opponent.locations[li] = {}
    end

    table.insert(eventLog, {
        text = "Turn " .. currentTurn .. " begins! You have " .. player.mana .. " mana.",
        timer = 3
    })

    uiDirtyFlags.handChanged = true
    uiDirtyFlags.boardChanged = true
end

function drawOneCard(who)
    if #who.deck > 0 and #who.hand < gameSettings.maxHandSize then
        table.insert(who.hand, table.remove(who.deck, 1))
        if who == player then
            uiDirtyFlags.handChanged = true
        end
    end
end


-- ─────────────────────────────────────────────────────────────────────────
--  DRAW A DIAMOND (for title screen separators)
-- ─────────────────────────────────────────────────────────────────────────
function drawDiamond(x, y, size)
    love.graphics.polygon("fill",
        x, y - size,
        x + size, y,
        x, y + size,
        x - size, y
    )
end

-- ─────────────────────────────────────────────────────────────────────────
--  DRAW CROWN EMBLEM (for title screen)
-- ─────────────────────────────────────────────────────────────────────────
function drawCrown(x, y)
    love.graphics.setColor(colors.gold)
    love.graphics.setLineWidth(3)
    local pts = {
        x - 30, y + 10,
        x - 20, y - 10,
        x - 10, y + 5,
        x,      y - 15,
        x + 10, y + 5,
        x + 20, y - 10,
        x + 30, y + 10
    }
    love.graphics.line(pts)
    love.graphics.setColor(colors.ember)
    love.graphics.circle("fill", x, y - 15, 4)
    love.graphics.circle("fill", x + 20, y - 10, 3)
    love.graphics.circle("fill", x - 20, y - 10, 3)
end

-- ─────────────────────────────────────────────────────────────────────────
--  DRAW “EPIC” BUTTON (REUSED FOR PLAY / SUBMIT / PLAY AGAIN)
-- ─────────────────────────────────────────────────────────────────────────
function drawEpicButton(btn)
    love.graphics.setFont(buttonFont)
    if btn.hover then
        love.graphics.setColor(colors.ember)
        love.graphics.rectangle("fill", btn.x - 5, btn.y - 5, btn.width + 10, btn.height + 10, 8, 8)
    end
    love.graphics.setColor(colors.bronze)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 6, 6)
    love.graphics.setColor(colors.gold)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 6, 6)
    love.graphics.setColor(colors.lightGold)
    love.graphics.print(
        btn.text,
        btn.x + btn.width/2 - buttonFont:getWidth(btn.text)/2,
        btn.y + btn.height/2 - buttonFont:getHeight()/2
    )
end