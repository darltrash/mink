local assets = require 'ass'
local lume   = require 'lib.lume'
local log    = require 'lib.log'
local utils  = require 'src.utils'

local COLOR_WHITE = {1, 1, 1, 1}
local COLOR_BLACK = lume.scolor("#360078")

COLLIDER_TYPE_UNKNOWN = -1
COLLIDER_TYPE_WORLD = 0
COLLIDER_TYPE_PARTICLE = 1
COLLIDER_TYPE_PLAYER = 2
COLLIDER_TYPE_NPC = 3

-- i have no fucking idea of what i'm doing, please cure me

local PRE_COLLIDER_FILTER = lume.memoize(function (a, b)
    if a == COLLIDER_TYPE_WORLD then return nil end
    if b == COLLIDER_TYPE_WORLD then
        return (a == COLLIDER_TYPE_PARTICLE) and "bounce" or "slide"
    end
    return nil
end)

local COLLIDER_FILTER = function (a, b)
    local atype = a.collider.type
    local btype = b.collider.type

    return PRE_COLLIDER_FILTER(atype, btype)
end

local AABB = function(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end

local stars = {}
lm.setRandomSeed(1996)
for i = 1, 200 do
    table.insert(stars, {
        x = lm.random(0, 500)/500,
        y = lm.random(0, 500)/500,
        s = lm.random(40, 300)/250,
        a = 0
    })
end
table.sort(stars, function(a, b) return a.s > b.s end)

lm.setRandomSeed(lt.getTime()*9000)

local world = {
    entities = {}, tiles = {},
    camera = { x = 0, y = -140, s = 3 },
    background1 = lume.scolor("#5f00d4"),
    background2 = lume.scolor("#c12fd1"),
    collision = require("lib.bump").newWorld(),
    player = {}, stars = stars,

    square = function(world, x, y, w, h)
        for _x=x, (x+w) do
            if lm.random(1, 3)==1 then
                world:addTile(_x, y-1, "tileset0", lm.random(1, 2), 3, false)
            end
        end
        for _x=x+1, (x+w)-1 do
            world:addTile(_x, y,   "tileset0", 1, 2)
            world:addTile(_x, y+h, "tileset0", 1, 0)
        end

        for _y=y+1, (y+h)-1 do
            world:addTile(x, _y,   "tileset0", 2, 1)
            world:addTile(x+w, _y, "tileset0", 0, 1)
        end

        world:addTile(x+w, y, "tileset0", 5, 0)
        world:addTile(x, y+h, "tileset0", 4, 0)
        world:addTile(x+w, y+h, "tileset0", 6, 0)

        for _x=x+1, (x+w)-1 do
            for _y=y+1, (y+h)-1 do
                world:addTile(_x, _y, "tileset0", 3, 1)
            end
        end
        world:addTile(x, y, "tileset0", 3, 0, true, w+1, h+1)
    end,

    addEntity = function(self, sys, tab)
        log.info("Attempting to create %s", sys)
        local s = log.assert(self.entityTypes[sys], "System %s not found!", sys)
        local ent = lume.extend(lume.clone(s), tab)
        table.insert(self.entities, ent)
        if ent.collider then
            self.collision:add(ent, ent.x, ent.y, ent.collider.w, ent.collider.h)
        end
        return ent
    end,

    addTile = function(self, x, y, atlas, sx, sy, c, cw, ch)
        local spr = self.sprite(atlas, sx, sy, 1, 1)

        local tile = {
            x = x * spr.w, y = y * spr.h, sprite = spr
        }
        
        self.tiles.baked  = nil
        self.tiles.offsetX = math.min(self.tiles.offsetX or 0, ((x<0) and x or 0) * spr.w)
        self.tiles.offsetY = math.min(self.tiles.offsetY or 0, ((y<0) and y or 0) * spr.h)
        self.tiles.width  = math.max(self.tiles.width or 0,  ((x + 1) - self.tiles.offsetX) * spr.w)
        self.tiles.height = math.max(self.tiles.height or 0, ((y + 1) - self.tiles.offsetY) * spr.h)

        if c then
            tile.collider = self.collider(spr.w * (cw or 1), spr.h * (ch or 1), COLLIDER_TYPE_WORLD)
            self.collision:add(tile, tile.x, tile.y, tile.collider.w, tile.collider.h)
        end
        table.insert(self.tiles, tile)
    end,

    sprite = lume.memoize(function(s, x, y, w, h)
        -- This assert thing is SUPER SLOW, thankfully this is all memoized

        log.assert(type(x) == "number", "Expected number as X, got %s!", type(x))
        log.assert(type(y) == "number", "Expected number as Y, got %s!", type(y))
        log.assert(type(w) == "number", "Expected number as W, got %s!", type(w))
        log.assert(type(h) == "number", "Expected number as H, got %s!", type(h))

        local t = log.assert(assets.atlases[s], "Atlas %s not found!", s)

        return {
            texture = t.texture, __sprite = true, 
            quad = lg.quad (        -- m e t a m e m o i z e
                x * t.w, y * t.h,
                w * t.w, h * t.h,
                t.texture:getWidth(), 
                t.texture:getHeight()
            ),
            w = w * t.w, h = h * t.h
        }
    end),

    collider = lume.memoize(function(w, h, t)
        log.assert(type(w) == "number", "Expected number as W, got %s!", type(w))
        log.assert(type(h) == "number", "Expected number as H, got %s!", type(h))
        return { w = w, h = h, type = t or -1 }
    end),

    entitySort = function(a, b) return (a.z or 0) < (b.z or 0) end,

    entOnScreen = function (self, ent)
        local entW, entH = 8, 8
        if ent.sprite then
            entW = ent.sprite.w * (ent.scaleX or 1)
            entH = ent.sprite.h * (ent.scaleY or 1)
        end

        return AABB(
            self.camera.x-(self.screenW/2), self.camera.y-(self.screenH/2),
            self.screenW, self.screenH,
            ent.x+(ent.offsetX or 0), ent.y+(ent.offsetY or 0), entW, entH
        )
    end,

    loop = function (self, delta)
        local w, h = lg.getDimensions()
        self.camera.s = math.max(1, math.floor(math.max(w, h)/250))
        self.screenW = w / self.camera.s
        self.screenH = h / self.camera.s

        if lk.isDown("g") then
            local vx, vy = lume.vector(math.rad(lm.random(0, 360)), 200)
            self:addEntity("particle", { y = self.player.y, x = self.player.x+16, vx = vx, vy = -300 })
        end

        for i, star in ipairs(self.stars) do
            star.x = (star.x - 0.03 * delta) % 1
            star.y = (star.y + math.sin(lt.getTime()*9+i) * 0.025 * delta) % 1
        end

        local nextGen = {}
        local processed = 0
        for _, ent in ipairs(self.entities) do
            local entOnScreen = self:entOnScreen(ent)
            if (not ent.asleep) and (entOnScreen or ent.processOffScreen)  then
                ent.onScreen = entOnScreen
                if ent.process then
                    ent.__processTime = lume.time(ent.process, ent, delta)
                end

                local goalX = (ent.x or 0) + (ent.vx or 0) * delta
                local goalY = (ent.y or 0) + ((ent.vy or 0) + (ent.gravAccel or 1)) * delta

                ent.gravAccel = (ent.gravAccel or 1) + delta*600

                if self.collision:hasItem(ent) then
                    local _goalX, _goalY = goalX, goalY
                    goalX, goalY, ent.collider.cols = self.collision:move(ent, goalX, goalY, COLLIDER_FILTER)
                    ent.onFloor = _goalY > goalY
                    ent.onWall = (goalX-_goalX ~= 0) and lume.sign(goalX-_goalX)
                    ent.gravAccel = ent.onFloor and 1 or ent.gravAccel
                    ent.impactX = math.abs(goalX-_goalX)
                    ent.impactY = math.abs(goalY-_goalY)
                    ent.impact = ent.impactX + ent.impactY
                end

                ent.tooltipAlpha = lume.lerp(ent.tooltipAlpha or 0, ent.tooltip and 1 or 0, delta*10)
                if ent.tooltipAlpha>0 then
                    local w, h = 16, 8
                    local fnt = assets.fonts.main
                    local bfnt = assets.fonts.bold
                    if ent.tooltipText then
                        w, h = utils.textSize(fnt, ent.tooltipText, bfnt)
                        w = w + 8
                        h = h + 4
                    end

                    ent.tooltipWidth = lume.lerp(ent.tooltipWidth or w, w, delta*4)
                    ent.tooltipHeight = lume.lerp(ent.tooltipHeight or h, h, delta*4)
                end

                ent.x = goalX
                ent.y = goalY
                processed = processed + 1
            end

            if ent.destroy or (ent.destroyOffScreen and not entOnScreen) then
                if self.collision:hasItem(ent) then
                    self.collision:remove(ent)
                end
            else
                table.insert(nextGen, ent)
            end
        end

        table.sort(nextGen, self.entitySort)
        self.entities = nextGen

        if DEBUGMODE then
            self.__debugInfo = ("entity amount: %s\nentities processed: %s"):format(#self.entities, processed)
        end
        return #nextGen
    end,

    resize = function(self, w, h)
        if self.mainCanvas then self.mainCanvas:release() end
        self.mainCanvas = lg.newCanvas(w, h)
        self.mainCanvas:renderTo(lg.clear)
    end,

    selection = { },
    mousepressed = function (self, x, y, btn)
        local mx, my = lc.getPosition()
        mx = ((mx/self.camera.s)+self.camera.x)-(self.screenW/2)
        my = ((my/self.camera.s)+self.camera.y)-(self.screenH/2)

        self.selection.x = math.floor(mx/8)
        self.selection.y = math.floor(my/8)
    end,

    mousereleased = function (self, x, y, btn)
        local mx, my = lc.getPosition()
        mx = ((mx/self.camera.s)+self.camera.x)-(self.screenW/2)
        my = ((my/self.camera.s)+self.camera.y)-(self.screenH/2)

        self:square(self.selection.x, self.selection.y, math.abs(math.floor(mx/8)-self.selection.x), math.abs(math.floor(my/8)-self.selection.y))
    end,

    draw = function (self)
        local mx, my = lc.getPosition()
        mx = ((mx/self.camera.s)+self.camera.x)-(self.screenW/2)
        my = ((my/self.camera.s)+self.camera.y)-(self.screenH/2)

        local w, h = lg.getDimensions()
        if not self.mainCanvas then
            self:resize(w, h)
        end

        lg.push()
        lg.setCanvas(self.mainCanvas)
            lg.clear()
            if not self.tiles.baked then
                self.tiles.baked = lg.newCanvas(self.tiles.width or 1, self.tiles.height or 1)
                
                lg.push()
                lg.setCanvas(self.tiles.baked)
                    for _, tile in ipairs(self.tiles) do
                        lg.setColor(tile.color or COLOR_WHITE)
                        lg.draw(tile.sprite.texture, tile.sprite.quad, tile.x-self.tiles.offsetX, tile.y-self.tiles.offsetY)

                        if DEBUGMODE and tile.collider then
                            lg.setColor(1, 0, 0, 0.2)
                            lg.rectangle("fill", tile.x-self.tiles.offsetX, tile.y-self.tiles.offsetY, tile.collider.w, tile.collider.h)
                            lg.rectangle("line", tile.x-self.tiles.offsetX, tile.y-self.tiles.offsetY, tile.collider.w, tile.collider.h)
                        end
                    end
                lg.setCanvas()
                lg.pop()
            end

            lg.scale(self.camera.s)

            local si = 1/self.camera.s
            love.graphics.translate(
                lume.round(-self.camera.x+(self.screenW/2), si), 
                lume.round(-self.camera.y+(self.screenH/2), si)
            )

            lg.setColor(COLOR_WHITE)
            lg.draw(self.tiles.baked, self.tiles.offsetX, self.tiles.offsetY)
            for _, ent in ipairs(self.entities) do
                if ent.invisible or not (ent.sprite and self:entOnScreen(ent)) then goto continue end
                local color = ent.color or COLOR_WHITE
                lg.setColor(color)

                if ent.preSprite then
                    lg.draw(
                        ent.preSprite.texture, ent.preSprite.quad,
                        lume.round(ent.x+(ent.preSprite.w/2), si)+(ent.offsetX or 0)+(ent.preOffsetX or 0),
                        lume.round(ent.y+(ent.preSprite.h/2), si)+(ent.offsetY or 0)+(ent.preOffsetY or 0), ent.rotation or 0,
                        (ent.scaleX or 1)*(ent.preScaleX or 1), (ent.scaleY or 1)*(ent.preScaleY or 1),
                        ent.preSprite.w/2, ent.preSprite.h/2
                    )
                end

                if ent.sprite then
                    lg.draw(
                        ent.sprite.texture, ent.sprite.quad,
                        lume.round(ent.x+(ent.sprite.w/2), si)+(ent.offsetX or 0),
                        lume.round(ent.y+(ent.sprite.h/2), si)+(ent.offsetY or 0), ent.rotation or 0,
                        ent.scaleX or 1, ent.scaleY or 1,
                        ent.sprite.w/2, ent.sprite.h/2
                    )
                end

                if ent.postSprite then
                    lg.draw(
                        ent.postSprite.texture, ent.postSprite.quad,
                        lume.round(ent.x+(ent.postSprite.w/2), si)+(ent.offsetX or 0)+(ent.postOffsetX or 0),
                        lume.round(ent.y+(ent.postSprite.h/2), si)+(ent.offsetY or 0)+(ent.postOffsetY or 0), ent.rotation or 0,
                        (ent.scaleX or 1)*(ent.postScaleX or 1), (ent.scaleY or 1)*(ent.postScaleY or 1),
                        ent.postSprite.w/2, ent.postSprite.h/2
                    )
                end

                if ent.tooltipAlpha>0 then
                    local fnt = assets.fonts.main
                    local w, h = ent.tooltipWidth, ent.tooltipHeight
                    local ew = ent.sprite.w
                    local eh = ent.sprite.h
                    local x = (ent.x+(ent.offsetX or 0)+(ew/2))-(w/2)
                    local y = (ent.y+(ent.offsetY or 0)+(math.sin(lt.getTime()*2)*ent.tooltipAlpha*3))-(h+4)
                    
                    lg.setColor(self.background1[1]-0.3, self.background1[2]-0.3, self.background1[3]-0.3, ent.tooltipAlpha)
                    lg.rectangle("fill", x, y, w, h, 2)
                    local ox = (w/2)-8
                    ---@diagnostic disable-next-line: redundant-parameter
                    lg.polygon("fill", ox+x+4, y+h, ox+x+8, y+h+4, ox+x+12, y+h)
                    if self.camera.s > 2 then
                        lg.rectangle("line", x, y, w, h, 2)
                        ---@diagnostic disable-next-line: redundant-parameter
                        lg.polygon("line", ox+x+4, y+h, ox+x+8, y+h+4, ox+x+12, y+h)
                    end

                    if ent.tooltipText then
                        lg.setColor(0, 0, 0, ent.tooltipAlpha)
                        utils.print(fnt, ent.tooltipText, x+4, y+3, nil, 1, ent.tooltipLimit, assets.fonts.bold)

                        lg.setColor(self.background2[1]+0.7, self.background2[2]+0.7, self.background2[3]+0.7, ent.tooltipAlpha)
                        utils.print(fnt, ent.tooltipText, x+4, y+2, {1, 0.6, 0.9, 1}, 1, ent.tooltipLimit, assets.fonts.bold)
                    else
                        lg.setColor(0, 0, 0, ent.tooltipAlpha)
                        lg.line(x+4, y+3, x+8, y+7)
                        lg.line(x+12, y+3, x+8, y+7)

                        lg.setColor(self.background2[1]+0.7, self.background2[2]+0.7, self.background2[3]+0.7, ent.tooltipAlpha)
                        lg.line(x+4, y+2, x+8, y+6)
                        lg.line(x+12, y+2, x+8, y+6)
                    end
                end

                ::continue::
            end
            lg.rectangle("fill", math.floor(mx/8)*8, math.floor(my/8)*8, 8, 8)
        lg.setCanvas()
        lg.pop()

        -- ////////////////////////////////////////////////////////////////////////////////////////////////////////

        lg.setColor(self.background1)
        lg.rectangle("fill", 0, 0, w, h)
        lg.setColor(self.background2)
        lg.draw(assets.atlases.hgradient.texture, 0, 0, 0, w, h/100)

        for _, star in ipairs(self.stars) do
            lg.setColor(1, 1, 1, (1-star.a)*0.2)

            local x, y = star.x*w, star.y*h
            local m = star.s*self.camera.s*3
            ---@diagnostic disable-next-line: redundant-parameter
            lg.polygon("fill", x-m, y, x, y-m, x+m, y, x, y+m)
        end

        lg.setColor(0, 0, 0, 0.2)
        lg.draw(self.mainCanvas, self.camera.s*2, self.camera.s*2)
        lg.setColor(COLOR_WHITE)
        lg.draw(self.mainCanvas)

        for _, star in ipairs(self.stars) do
            local x, y = ((star.y*w)-(self.camera.x*2*star.s))%w, (star.x*3)*h
            local m = star.s*self.camera.s*1
            
            lg.setColor(1, 1, 1, (1-star.a)*0.4*(star.x*10))
            ---@diagnostic disable-next-line: redundant-parameter
            lg.polygon("fill", x-m, y, x, y-m, x+m, y, x, y+m)
        end

        lg.setColor(self.background2[1], self.background2[2], self.background2[3], 0.25)
        lg.draw(assets.atlases.hgradient.texture, 0, 0, 0, w, h/100)

        -- ////////////////////////////////////////////////////////////////////////////////////////////////////////

        if NODBGOVERLAY or not DEBUGMODE then return end -- //////////////////////////////////////////////////////

        lg.push()
        lg.scale(self.camera.s)
        lg.setColor({1, 1, 1, 0.1})
        lg.line(0, self.screenH/2, self.screenW, self.screenH/2)
        lg.line(self.screenW/2, 0, self.screenW/2, self.screenH)
        
        local si = 1/self.camera.s
        lg.translate(
            lume.round(-self.camera.x+(self.screenW/2), si),
            lume.round(-self.camera.y+(self.screenH/2), si)
        )

        local ns = 1000000000
        local ou = 0
        for _, ent in ipairs(self.entities) do
            local color = ent.color or COLOR_WHITE

            if ent.collider then
                lg.setColor(color[1], color[2], color[3], 0.5)
                lg.rectangle("line", ent.x, ent.y, ent.collider.w, ent.collider.h)
            end

            lg.setLineWidth(1)
            lg.setLineStyle("rough")
            lg.line(ent.x-3, ent.y, ent.x+3, ent.y)
            lg.line(ent.x, ent.y-3, ent.x, ent.y+3)

            if ent.area then
                lg.circle("line", ent.x+(ent.areaX or 0), ent.y+(ent.areaY or 0), ent.area, ent.area*0.3)
            end

            local fnt = assets.fonts.main

            lg.setFont(fnt)
            local txt = ("name: *%s*\nprocess: *%.0fns*"):format(ent.__name or "UNKNOWN", (ent.__processTime or 0)*ns)
            local h = fnt:getHeight(txt)
            utils.print(
                fnt, txt, lume.round(ent.x, si), lume.round(ent.y-(h), si), {1, 1, 1, 1}, 1/self.camera.s
            )
            
            ou = ou + (ent.__processTime or 0)
        end
        
        self.__debugInfo = self.__debugInfo .. "\nentity time: " .. math.floor(ou*ns) .. "ns\ncursorpos: " .. (math.floor(mx/8)*8) .. ", " .. (math.floor(my/8)*8)
        lg.pop()
    end
}
package.loaded.world = world
world.entityTypes = require("ent")

return world