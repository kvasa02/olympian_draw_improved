PROGRAMMING PATTERNS:
I drew inspiration from several programming patterns outlined in Robert Nystrom’s Game Programming Patterns. These helped me keep the code organized, maintainable, and easier to debug as the project grew.
One of the most important patterns I used was the Flyweight Pattern. I applied this in two key places: the number quads used to display animated “+N/−N” point updates, and the card system. For the digits, I sliced a single number sprite sheet into quads and reused them for all point animations—this way, I didn’t have to load or duplicate images for every animation. Similarly, all card definitions (like Zeus, Ares, etc.) share a prototype object stored in cards.lua. At runtime, I only copy the data I need for each individual card (like flipped state or unique ID), while all the static properties (like name, cost, power, effects) remain shared. This made memory usage more efficient and simplified how I handled card instances.

I also relied heavily on the Event Queue Pattern, although not through a dedicated message system. Instead, I used a few simple queues: the event log (which displays messages in the lower left corner), a reveal queue for animating the staged cards in order, and a point queue that drives the flying point indicators. These queues allowed me to decouple the action from its animation timing, letting things happen smoothly over multiple frames.

To manage the flow of the game, I built a simple Finite State Machine using a gameState variable ("title", "game", "gameover") and a gamePhase variable ("staging", "show_ai", "revealing", etc.). Instead of creating separate classes for each state, I controlled behavior by checking these values in love.update(dt) and love.draw(). This pattern helped organize what should happen when—for example, only allowing players to drag cards during the "staging" phase or animating AI moves during "show_ai."

The overall structure of the game logic follows the Update Method Pattern. Every frame, I call love.update(dt), which steps through timers, updates animations, handles card reveals, and transitions between game phases. This centralized update loop made it easy to control timing-sensitive elements like card flipping or point animations without spreading logic all over the place.

Another pattern that shaped how I handled cards was the Prototype Pattern. All cards are created using CardPrototype:new() and stored in cards.lua. I don’t manually rebuild card data each time; instead, I clone the prototype and then assign dynamic values like flipped state or temporary buffs. This pattern made card creation very scalable and let me implement special effects on a per-card basis using hooks like onPlay or onReveal.

For the cards themselves, I treated their abilities as interchangeable parts by using a Component Pattern. Each card is a simple table holding data like its cost and power. I then attached behaviors, like onPlay or onReveal functions, directly to individual card definitions. This approach allowed me to design new cards with unique effects by simply composing different data and functional components, rather than building a complex and rigid class hierarchy.

To handle services like audio without having to pass an instance everywhere, I used a Service Locator Pattern. I created a global Audio module that is loaded once when the game starts. This provides a centralized, globally accessible point for all audio-related functions. Any part of the code can now call Audio:playBGM() directly, which kept the rest of the codebase clean and decoupled from the audio system's implementation.

The visual effects for played cards could have caused performance issues, as creating and destroying many small objects can be slow. To solve this, I implemented an Object Pool Pattern for the particle system. At launch, I pre-allocate a large pool of particle objects that are all set to "inactive". When an effect occurs, my spawnParticles function finds and re-initializes objects from this pool instead of creating new ones. When a particle's life ends, it is simply marked as inactive and returned to the pool, ready to be used again. This completely avoids runtime memory allocation for particles, leading to much smoother performance.

Finally, to make the drag-and-drop logic for placing cards efficient, I used a simple form of a Spatial Partition Pattern. Rather than checking for collisions against every slot on the screen, I grouped the card slots into three lists based on their location index. When the player drags a card over the board, I only need to check for a valid drop target within the list corresponding to that specific location. This partitioning of the game world simplified the collision-checking logic and made it more performant.


ASSETS:
SPRITES & IMAGES:
* Background: https://www.istockphoto.com/vector/mystery-cave-with-sci-fi-building-gm613687432-105977845
* Block Numbers: https://biscuitlocker.itch.io/pixel-block-numbers-gameboy
* Card Frames: 
    * https://piposchpatz.itch.io/card-frame-template
    * https://tornioduva.itch.io/dd-card-sheet
    * https://tornioduva.itch.io/tornioduva-card-pack?download

AUDIO:
* Background Music: https://pixabay.com/music/main-title-cinematic-efx-for-greek-and-roman-143708/

