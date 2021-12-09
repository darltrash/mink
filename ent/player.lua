local lume = require("lib.lume")
local world = require("world")
local control = require("control")
local assets = require("ass")

local SND_FOOT = assets.sounds.footsteps
local SND_SCRE = assets.sounds.scream
SND_SCRE:setLooping(true)
SND_SCRE:setVolume(0)
SND_SCRE:play()

local SPR_MAIN = world.sprite("player0", 0, 0, 1, 1)
local SPR_FALL = world.sprite("player0", 3, 0, 1, 1)
local SPR_CROU = world.sprite("player0", 4, 0, 1, 1)
local SPR_GRAB = world.sprite("player0", 5, 0, 1, 1)
local SPR_SCRE = world.sprite("player0", 6, 0, 1, 1)
local SPR_PUNC = world.sprite("player0", 7, 0, 1, 1)
local SPR_ANIM = {
    world.sprite("player0", 1, 0, 1, 1),
    SPR_MAIN,
    world.sprite("player0", 2, 0, 1, 1),
    SPR_MAIN,
}

return {
    x = 0, y = 0, z = 0, jumpValue = 0, timer = 1, _flip = 1, scaleX = 1, scaleY = 1, screaming = false,
    vx = 0, vy = 0, collider = world.collider(20, 28), anim = 1, preScaleX = 0, preSprite = SPR_PUNC,
    offsetX = -6, offsetY = -4, sprite = SPR_MAIN, mashing = false, canWallgrab = true,

    process = function(self, delta)
        world.player = self

        local vx, vmj, vm = 0, 300, 140
        local s, ps, offset = 1, 0, -4

        self.wallGrabbing = false
        self.canWallgrab = (self.canWallgrab or self.onFloor or not self.onWall) and not self.screaming

        if self.onFloor then
            self.jumpValue = 0
            if self.impactY > 0.18 then
                world:addEntity("dust", { x = self.x-8, y = self.y })
            end
        elseif self.onWall and control.grab and self.canWallgrab then
            self.gravAccel = 0
            self.jumpValue = 0
            self.wallGrabbing = true
        end

        if not self.freeze then
            if control.moveLeft then
                vx = -1
                self._flip = -1
            end

            if control.moveRight then
                vx = 1
                self._flip = 1
            end

            if control.run then
                vm = 190
            end

            if control.jump then
                if self.onFloor then
                    self.jumpValue = 1
                    self.gravAccel = 0

                    world:addEntity("dust", { x = self.x-8, y = self.y })
                    SND_FOOT:stop()
                    SND_FOOT:setVolume(0.5)
                    SND_FOOT:play(0)
                elseif self.wallGrabbing then
                    self.jumpValue = 1
                    self.gravAccel = 0

                    SND_FOOT:stop()
                    SND_FOOT:setVolume(0.5)
                    SND_FOOT:play(0)
                    self.canWallgrab = false
                end
            end
        end

        if self.jumpValue > 0 then
            self.sprite = SPR_FALL
            if self.gravAccel < self.jumpValue * 200 then
                self.sprite = SPR_ANIM[1]
            end
        else
            if self.wallGrabbing then
                self.timer = 1
                self.sprite = SPR_GRAB

            elseif not self.onFloor then
                self.timer = 1
                self.sprite = SPR_FALL

            elseif control.crouch then
                self.timer = 0
                self.sprite = SPR_CROU
                self.vx = 0

            elseif vx ~= 0 then
                self.timer = self.timer + (vm/20) * delta
                if self.timer >= 1 then 
                    self.anim = self.anim + 1
                    if self.anim >= 5 then
                        self.anim = 1
                    end
                    
                    if self.anim == 1 or self.anim == 3 then
                        SND_FOOT:stop()
                        SND_FOOT:setVolume(math.random(80, 120)/140)
                        SND_FOOT:play(0)
                    end
                    self.timer = 0
                end
                if self.anim == 1 or self.anim == 3 then
                    offset = -8
                end
                
                self.sprite = SPR_ANIM[self.anim]
            else
                self.timer = 50
                self.anim = 1
                self.sprite = SPR_MAIN
            end
        end

        self.postSprite = nil
        self.screaming = false
        self.petting = false
        
        if not self.freeze then
            if control.attack then
                self.postSprite = SPR_SCRE
                s = 1.25
                self.screaming = true
                self.postOffsetY = 0
                if self.sprite == SPR_CROU then
                    self.postOffsetY = 3
                end
            end

            if control.pet and self.sprite~=SPR_CROU then
                ps = 1
                self.petting = true
                self.preOffsetX = lm.random(-2, 2)/2
                self.preOffsetY = lm.random(-2, 2)/2
            end
        end

        self.scaleY = lume.lerp(self.scaleY, s, delta * 5)
        self.scaleX = lume.lerp(self.scaleX, self._flip, delta * 16)

        self.offsetY = lume.lerp(self.offsetY, offset-((self.scaleY-1)*16), delta*40)
        self.preScaleX = lume.lerp(self.preScaleX, ps,  delta * 20)

        self.vx = lume.lerp(self.vx, vx * vm, delta * 8)
        self.vy = self.jumpValue * -vmj

        SND_SCRE:setPosition(self.x+16, self.y+16, 0)
        SND_SCRE:setVolume((self.scaleY-1)*0.09)
        SND_SCRE:setPitch((math.sin(lt.getTime()*20)*0.06)+1+(self.scaleY-1)*2)
        SND_FOOT:setPosition(self.x+16, self.y+32, 0)

        la.setDistanceModel("exponentclamped")
        la.setPosition(self.x+16, self.y+16, 0)
        la.setVolume(NOVOLUME and 0 or 8.0)

        if self.freeze then return end

        world.camera.x = lume.lerp(world.camera.x, self.x+8, delta*8)
        world.camera.y = lume.lerp(world.camera.y, (self.y+8) + (self.sprite == SPR_CROU and 32 or 0), delta*8)
    end
}