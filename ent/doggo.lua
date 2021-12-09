local world = require("world")
local assets = require("ass")
local lume = require("lib.lume")

local SPR_MAIN = world.sprite("dog", 1, 0, 1, 1)
local SPR_BARK = world.sprite("dog", 0, 0, 1, 1)

return {
    x = 0, y = 0, vx = 0, vy = 0, collider = world.collider(32, 32, COLLIDER_TYPE_NPC),
    timer = 0, sprite = SPR_MAIN, z = -1, color = {1, 1, 1, 1}, area = 20, areaX = 16, areaY = 16,
    process = function(self, delta)
        if lume.distance(self.x+self.areaX, self.y+self.areaY, world.player.x or 0, world.player.y or 0) < self.area and world.player.petting then
            self.timer = self.timer + delta
        end
        if self.timer > 2 then
            assets.sounds.bark:setVolume(0.1)
            assets.sounds.bark:setPosition(self.x+16, self.y+16)
            assets.sounds.bark:play()
            
            self.sprite = SPR_BARK
            self.asleep = true
        end
    end
}