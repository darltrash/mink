local world = require("world")
local assets = require("ass")
local lume = require("lib.lume")

local SPR_DYIN = world.sprite("test_boombox", 1, 0, 1, 1)
local SPR_MAIN = world.sprite("test_boombox", 0, 0, 1, 1)
local SPR_DEBR = world.sprite("test_boombox", 0.5, 0.5, 0.25, 0.25)

return lume.extend(lume.clone(require("ent.destructable")), {
    sprite = SPR_MAIN, music = assets.music.breakdance, debris = SPR_DEBR,
    collider = world.collider(32, 18, COLLIDER_TYPE_NPC), processOffScreen = true,
    offsetY  = -14, pitch = 1.0, z = -2,

    runCallback = function(self)
        self.sprite = self.dying and SPR_DYIN or SPR_MAIN

        if not self.musicPlaying then
            self.music:setLooping(true)
            self.music:setVolume(1.5)
            self.music:setAirAbsorption(1000)
            self.music:setPosition(self.x+16, self.y+8)
            self.music:play()
            self.processOffScreen = false
            self.musicPlaying = true
        end

        self.music:setPitch(self.pitch + math.max(math.random(-1, 1) * (self.timer/10), 0))
    end,

    destroyCallback = function(self)
        self.music:stop()
    end
})