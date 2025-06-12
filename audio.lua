-- audio.lua
local Audio = {}
Audio.__index = Audio

function Audio:load()
    self.sounds = {
        bgm = love.audio.newSource("assets/audio/game.mp3", "stream")
    }

    -- Enable looping for background music
    self.sounds.bgm:setLooping(true)
end

function Audio:playBGM()
    local bgm = self.sounds.bgm
    if bgm and not bgm:isPlaying() then
        bgm:play()
    end
end

function Audio:stopBGM()
    local bgm = self.sounds.bgm
    if bgm and bgm:isPlaying() then
        bgm:stop()
    end
end

return setmetatable({}, Audio)
