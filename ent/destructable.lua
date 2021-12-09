local world = require("world")
local lume = require("lib.lume")

local SPR = world.sprite("tileset0", 0, 0, 2, 2)
return {
    x = 0, y = 0, sprite = SPR, debris = SPR, vx = 0, vy = 0, z = -1,
    collider = world.collider(16, 16, COLLIDER_TYPE_WORLD), timer = 0, areaX = 16, areaY = 16,
    dying = false, area = 60,

    process = function (self, delta)
        self.dying = false
        if world.player.screaming and lume.distance(self.x+self.areaX, self.y+self.areaY, (world.player.x or 0) + 16, world.player.y or 0) < self.area  then
            self.timer = self.timer + delta * 20
            self.dying = true
        else
            self.timer = math.max(self.timer - delta * 20, 0)
        end

        self.offsetY = -14 + (math.random(-1, 1) * (self.timer/10))
        self.offsetX = math.random(-1, 1) * (self.timer/10)

        self.scaleX = 1 + ((math.random(-50, 50)/100) * (self.timer/20))
        self.scaleY = 1 + ((math.random(-50, 50)/100) * (self.timer/20))

        if self.runCallback then
            self:runCallback(delta)
        end

        if self.timer > 30 then
            self.destroy = true
            for i=1, 8 do
                local vx, vy = lume.vector(math.rad(lm.random(0, 360)), 1)
                vy = -1
                world:addEntity("particle", {
                    x = self.x+16+math.random(-6, 6), y = self.y+math.random(-6, 6), vx = vx*200, vy = vy*300, sprite = self.debris
                })
            end
            if self.destroyCallback then
                self:destroyCallback(delta)
            end
        end
    end
}