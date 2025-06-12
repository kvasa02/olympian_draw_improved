local CardPrototype = require("CardPrototype")

return {
    WoodenCow = CardPrototype:new{
        name = "Wooden Cow",
        cost = 1,
        power = 1,
        text = "Vanilla",
        imagePath = "assets/cards/woodencow.png"
    },
    
    Pegasus = CardPrototype:new{
        name = "Pegasus",
        cost = 3,
        power = 5,
        text = "Vanilla",
        imagePath = "assets/cards/pegasus.png"
    },
    
    Minotaur = CardPrototype:new{
        name = "Minotaur",
        cost = 5,
        power = 9,
        text = "Vanilla",
        imagePath = "assets/cards/minotaur.png"
    },

    Titan = CardPrototype:new{
        name = "Titan",
        cost = 6,
        power = 12,
        text = "Vanilla",
        imagePath = "assets/cards/titan.png"
    },

    
    Zeus = CardPrototype:new{
        name = "Zeus", -- Make sure this line is present!
        cost = 6,      -- Updated cost from a later version of your cards.lua
        power = 7,     -- Updated power from a later version of your cards.lua
        text = "When Revealed: Lower the power of each card in your opponent's hand by 1.", -- Updated text
        imagePath = "assets/cards/zeus.png", -- Ensure image path is there
        onReveal = function(self)
            local currentOpponent = _G.currentOpponent or opponent
            for _, card in ipairs(currentOpponent.hand) do
                card.power = math.max(0, card.power - 1)
            end
        end
    },

    Ares = CardPrototype:new{
        name = "Ares",
        cost = 4,
        power = 6,
        text = "When Revealed: Gain +2 power for each enemy card here.",
        imagePath = "assets/cards/ares.png",
        onReveal = function(self, locationIndex)
            local currentOpponent = _G.currentOpponent or opponent
            local enemyCount = #currentOpponent.locations[locationIndex]
            self.power = self.power + 2 * enemyCount
        end
    },

    Hera = CardPrototype:new{
        name = "Hera",
        cost = 3,
        power = 3,
        text = "When Revealed: Give cards in your hand +1 power.",
        imagePath = "assets/cards/hera.png",
        onReveal = function(self)
            local currentPlayer = _G.currentPlayer or player
            for _, card in ipairs(currentPlayer.hand) do
                card.power = card.power + 1
            end
        end
    },

    Apollo = CardPrototype:new{
        name = "Apollo",
        cost = 2,
        power = 2,
        text = "When Revealed: Gain +1 mana next turn.",
        imagePath = "assets/cards/apollo.png",
        onReveal = function(self)
            local currentPlayer = _G.currentPlayer or player
            currentPlayer.manaNext = (currentPlayer.manaNext or currentPlayer.mana) + 1
        end
    },

    Demeter = CardPrototype:new{
        name = "Demeter",
        cost = 2,
        power = 2,
        text = "When Revealed: Both players draw a card.",
        imagePath = "assets/cards/demeter.png",
        onReveal = function(self)
            -- Both players draw regardless of who played this
            if #player.deck > 0 and #player.hand < gameSettings.maxHandSize then
                table.insert(player.hand, table.remove(player.deck, 1))
            end
            if #opponent.deck > 0 and #opponent.hand < gameSettings.maxHandSize then
                table.insert(opponent.hand, table.remove(opponent.deck, 1))
            end
        end
    },

    Hades = CardPrototype:new{
        name = "Hades",
        cost = 4,
        power = 4,
        text = "When Revealed: Gain +2 power for each card in your discard pile.",
        imagePath = "assets/cards/hades.png",
        onReveal = function(self)
            local currentPlayer = _G.currentPlayer or player
            self.power = self.power + 2 * #currentPlayer.discard
        end
    },

    Artemis = CardPrototype:new{
        name = "Artemis",
        cost = 3,
        power = 4,
        text = "When Revealed: Gain +5 power if there is exactly one enemy card here.",
        imagePath = "assets/cards/artemis.png",
        onReveal = function(self, locationIndex)
            local currentOpponent = _G.currentOpponent or opponent
            if #currentOpponent.locations[locationIndex] == 1 then
                self.power = self.power + 5
            end
        end
    },

    Cyclops = CardPrototype:new{
        name = "Cyclops",
        cost = 5,
        power = 5,
        text = "When Revealed: Discard your other cards here, gain +2 power per discarded card.",
        imagePath = "assets/cards/cyclops.png",
        onReveal = function(self, locationIndex)
            local currentPlayer = _G.currentPlayer or player
            local newAllies = {}
            local count = 0
            
            for _, c in ipairs(currentPlayer.locations[locationIndex]) do
                if c ~= self then
                    table.insert(currentPlayer.discard, c)
                    count = count + 1
                else
                    table.insert(newAllies, c)
                end
            end
            
            currentPlayer.locations[locationIndex] = newAllies
            self.power = self.power + 2 * count
        end
    }
}