local world = require("world")
local lume = require("lib.lume")
local control = require("control")
local INST_MOVE = 0
local INST_TALK = 1

return {
    area = 70, areaX = 16, areaY = 16, z = -1, collider = world.collider(32, 32, COLLIDER_TYPE_NPC),
    script = nil, currScript = nil, timer = 0, dialogSound = require("ass").sounds.plink:clone(),

    say = function(self, text)
        self.tooltip = true
        self.tooltipText = text
        self.tooltipLength = #text
        self.tooltipLimit = 0
        self.timer = 0
        coroutine.yield(INST_TALK)
        self.tooltipText = nil
    end,

    move = function(self, x, y, ms)
        self.vx = x
        self.vy = y

        self.timer = lt.getTime()
        while (self.timer+ms)>=lt.getTime() do
            coroutine.yield(INST_MOVE)
        end
        self.timer = nil
        self.vx = x
        self.vy = y
    end,

    process = function (self, delta)
        if self.currScript then
            self.scaleX = lume.lerp(self.scaleX, self._flipx or lume.sign(world.player.x-(self.x+16)), delta*5)

            world.player.freeze = true
            world.player._flip = lume.sign(self.x - world.player.x)

            world.camera.x = lume.lerp(world.camera.x, self.x+(self.sprite.w/2), delta*4)
            world.camera.y = lume.lerp(world.camera.y, self.y+(self.sprite.h/2), delta*4)

            local done = false
            if self.inst==INST_TALK then
                self.timer = self.timer + delta * (control.run and 30 or 24)
                if self.timer > 1 and self.tooltipLimit < self.tooltipLength then
                    self.dialogSound:setVolume(3)
                    self.tooltipLimit = self.tooltipLimit+1
                    --self.dialogSound:stop()
                    self.dialogSound:play()
                    self.timer = 0
                end
                
                done = self.tooltipLimit == self.tooltipLength and control.accept
            elseif self.inst==INST_MOVE then
                -- NOTHING SO FAR....
                self._flipx = lume.sign(self.vx)
            end

            if done then
                _, self.inst = coroutine.resume(self.currScript, self)
            end
            if not self.inst then 
                self.currScript = nil
                world.player.freeze = false
            end
            self.processOffScreen = self.inst ~= nil

            return
        end

        self.scaleX = lume.lerp(self.scaleX, lume.sign(world.player.x-(self.x+16)), delta*5)
        if not self.script then return end

        self.tooltip = nil
        if lume.distance(self.x+self.areaX, self.y+self.areaY, (world.player.x or 0) + 16, world.player.y or 0) < self.area then
            self.tooltip = true
            if control.use then
                self.currScript = coroutine.create(self.script.onPlayerInteract)
                _, self.inst = coroutine.resume(self.currScript, self)
            end
        end
    end
}