local world = require("world")
local lume = require("lib.lume")
local assets = require("ass")

return {
    x = 0, y = 0, timer = 0, rotation = 0, vx = 0, vy = 0,
    sprite = world.sprite("spritesheet0", 0, 0, 1, 1), gravity = true,
    collider = world.collider(8, 8, COLLIDER_TYPE_PARTICLE), destroyOffScreen = true,

    process = function (self, delta)
        if not self.sound then
            self.sound = assets.sounds.plink:clone()
        end

        if (self.impact or 0)>0.1 then
            self.sound:setVolume(self.impact/2)
            self.sound:setPosition(self.x, self.y, 0)
            self.sound:setPitch(math.max((self.impact/2), 0.2))
            self.sound:play()
        end

        local power = math.abs(self.vx) + math.abs(self.vy)
        if power<30 then
            self.timer = self.timer + delta * 64
            if self.timer > 3 then
                self.timer = 0
                self.invisible = not self.invisible
            end
        end

        self.vx = lume.lerp(self.vx, 0, delta * 0.4)
        self.vy = lume.lerp(self.vy, 0, delta * 0.5)

        self.rotation = self.rotation + (self.vx/5000)
        self.destroy = (power<10)

        if not self.gravity then
            self.gravAccel = 0
        end

        self.z = 1
    end
}