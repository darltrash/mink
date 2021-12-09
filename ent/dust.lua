local world = require("world")

local sprites = {}
for x=0, 5 do
    table.insert(sprites, world.sprite("dust", x, 0, 1, 1))
end

return {
    x = 0, y = 0, vx = 0, vy = 0, sprites = sprites, timer = 1,
    destroyOffScreen = true, animVel = 16, offsetY = -3,

    process = function(self, delta)
        self.gravAccel = 0
        self.sprite = self.sprites[math.floor(self.timer)]
        self.timer = self.timer + delta * self.animVel

        self.destroy = self.timer > (#self.sprites)+1
    end
}