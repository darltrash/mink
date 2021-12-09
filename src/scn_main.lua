local world = require "src.world"
local lume  = require "lib.lume"
local lang  = require "lan"

return {
    init = function (self)
        world:square(-40, -20, 44, 54)
        world:square(5, 10, 15, 14)
        world:square(21, 0, 30, 24)
        world:square(52, 6, 50, 24)

        world:addEntity("player",  { y = -30, x =  50 })
        world:addEntity("boombox", { x = 360, y = -10 })
        world:addEntity("doggo",   { x = 200, y = -10 })
        world:addEntity("npc",     { x = 480, y =  30,   sprite = world.sprite("flowa", 0, 0, 1, 1), script = require("scr.000_mrflower") })
        world:addEntity("npc",     { x = -200, y = -200, sprite = world.sprite("player0", 0, 0, 1, 1), script = require("scr.000_clonegoat")})

        world:addEntity("npc", { x = 770, y = 30, sprite = world.sprite("angeldeer", 0, 0, 1, 1),
            collider = world.collider(30, 28, COLLIDER_TYPE_NPC), script = require("scr.000_deertransport")
        })
    end,

    mousepressed = function(self, x, y, btn)
        world:mousepressed(x, y, btn)
    end,

    mousereleased = function(self, x, y, btn)
        world:mousereleased(x, y, btn)
    end,

    loop = function (self, delta)
        world:loop(delta)
    end,

    resize = function(self, w, h)
        world:resize(w, h)
    end,

    draw = function (self)
        world:draw()
        self.__debugInfo = world.__debugInfo
    end
}