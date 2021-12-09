local world = require "world"
local lume  = require "lib.lume"

return { 
    x = 0, y = 0, z = -1, vx = 0, vy = 0, sprite = world.sprite("flowa", 0, 0, 1, 1),
    collider = world.collider(32, 32), area = 70, areaX = 16, areaY = 16,

    process = function (self, delta)
        self.scaleX = lume.lerp(self.scaleX, lume.sign(world.player.x-(self.x+16)), delta*5)

        self.tooltip = nil
        if lume.distance(self.x+self.areaX, self.y+self.areaY, (world.player.x or 0) + 16, world.player.y or 0) < self.area then
            self.tooltip = true
        end
    end
}