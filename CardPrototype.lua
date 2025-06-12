-- CardPrototype.lua
-- Base prototype for every card. Each card instance inherits these methods.

local CardPrototype = {}
CardPrototype.__index = CardPrototype

function CardPrototype:new(def)
    local card = setmetatable({}, self)
    for k, v in pairs(def) do
        card[k] = v
    end
    card.id = math.random(1000000)

    -- Load image if imagePath is specified
    if card.imagePath then
        card.image = love.graphics.newImage(card.imagePath)
    end

    return card
end

function CardPrototype:onPlay(locationIndex) end

function CardPrototype:onReveal(locationIndex) end

function CardPrototype:onEndOfTurn(locationIndex) end

function CardPrototype:onOtherCardPlayedHere(playedCard, locationIndex) end

function CardPrototype:onDiscard() end

return CardPrototype