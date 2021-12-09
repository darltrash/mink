#!/usr/bin/love .

--    Copyright 2021 (C) Nelson "darltrash" Lopez
--    All rights reserved

local lume = require("lib.lume")
local log  = require("lib.log")
local lynp = require("lib.Lynput")
local lang = require("lan")

_G.DEBUGMODE    = tonumber(os.getenv("MINK_DEBUG")         ) == 1
_G.EDITMODE     = tonumber(os.getenv("MINK_EDIT")          ) == 1
_G.NODBGOVERLAY = tonumber(os.getenv("MINK_NODEBUGOVERLAY")) == 1
_G.NOVOLUME     = tonumber(os.getenv("MINK_NOVOLUME")      ) == 1

-- SETUP LOG STUFF:
log.usecolor = jit.os ~= "Windows" -- lmao
log.level = DEBUGMODE and "trace" or "fatal"

lang.scan()
lang.setLanguageByCode(os.getenv("LANG"):sub(1, 2))

-- SETUP LYNPUT CONTROLLER STUFF:
lynp.load_gamepad_callbacks()
lynp.load_mouse_callbacks()
lynp.load_key_callbacks()

local control = lynp()
control:bind("moveLeft",{
    "hold left",
    "-100:0 G_LEFTSTICK_X"
})
control:bind("moveRight", {
    "hold right",
    "0:100 G_LEFTSTICK_X"
})
control:bind("crouch", {
    "hold down"
})
control:bind("jump", {
    "hold space"
})
control:bind("run", {
    "hold z"
})
control:bind("attack", {
    "hold c"
})
control:bind("grab", {
    "hold x"
})
control:bind("pet", {
    "hold a"
})
control:bind("use", {
    "hold d"
})
control:bind("accept", "hold s")
package.loaded.control = control

-- SETUP SOME OTHER STUFF LOL:
math.random = love.math.random
os.clock    = love.timer.getTime
lume.mcolor = lume.memoize(lume.color)
lume.scolor = function(...) return { lume.mcolor(...) } end

-- SETUP CACHING FOR LOVE2D BASICS:
love.graphics.quad   = lume.memoize(love.graphics.newQuad)
love.graphics.image  = lume.memoize(love.graphics.newImage)
love.graphics.shader = lume.memoize(love.graphics.newShader)
love.graphics.font   = lume.memoize(love.graphics.newFont)
love.audio.source    = lume.memoize(love.audio.newSource)

-- SHORTEN LOVE2D NAMESPACE STUFF:
_G.lf = love.filesystem
_G.lk = love.keyboard
_G.lg = love.graphics
_G.lw = love.window
_G.lc = love.mouse
_G.la = love.audio
_G.lt = love.timer
_G.ld = love.data
_G.lm = love.math

-- SETUP RESIZING MODE STUFF
local resizeFont = require("ass").fonts.main
local resizeTimer = 0

-- SETUP SCENE STUFF:
local currentScene
local scenes = {
    main = require("src.scn_main")
}

function SwapScene(scn)
    currentScene = log.assert(scenes[scn], "Scene %s does not exist!", scn)
    log.info(("Loaded scene %s"):format(scn))
    currentScene:init()
end

function love.resize(w, h)
    --resizeTimer = 10
    if currentScene.resize then
        currentScene:resize(w, h)
    end
end

function love.mousepressed(x, y, btn)
    if currentScene.mousepressed then
        currentScene:mousepressed(x, y, btn)
    end
end

function love.mousereleased(x, y, btn)
    if currentScene.mousereleased then
        currentScene:mousereleased(x, y, btn)
    end
end

-- SETUP MAIN LOOP:
function love.load()
    lw.setMode(996, 640, { vsync = DEBUGMODE and 0 or 1, resizable = true })
    lw.setTitle("Mink" .. (DEBUGMODE and " (DEBUG MODE)" or ""))
    SwapScene("main")
end

local updateTime, _updateTime = 0, 0
function love.update(delta)
    lynp.update_(delta)
    if resizeTimer > 0 then 
        resizeTimer = math.max(0, resizeTimer - delta*12)
        return
    end
    
    updateTime = lume.time(currentScene.loop, currentScene, delta)
end

local drawTime, _drawTime = 0, 0
function love.draw()
    if resizeTimer > 0 then
        local w, h = lg.getDimensions()

        lg.setBackgroundColor(0x16/255, 0x16/255, 0x1b/255, 0xff/255)
        lg.setFont(resizeFont)
        local text = "RESIZING!"
        if w<300 or h<250 then 
            resizeTimer = 10
            text = "TOO TINY!"
        end 
        local tw, th = resizeFont:getWidth(text), resizeFont:getHeight(text)
        lg.print(text, (w/2)-(tw/2), (h/2)-(th/2))
        print(resizeTimer)
        return
    end

    lg.push()
        drawTime = lume.time(currentScene.draw, currentScene)
    lg.pop()

    if not DEBUGMODE then return end

    lg.setFont(require("ass").fonts.main)
    local ns = 	1000000000 
    local delta = lt.getDelta()

    _updateTime = lume.lerp(_updateTime, updateTime*ns, delta)
    _drawTime = lume.lerp(_drawTime, drawTime*ns, delta)
    local txt = ("fps: %s\nupdate: %.0fns\ndraw: %.0fns\n%s"):format(lt.getFPS(), _updateTime, _drawTime, currentScene.__debugInfo or "")

    lg.scale(2)
    lg.setColor(0, 0, 0, 0.8)
    lg.print(txt, 8, 9)
    lg.setColor(1, 1, 1, 1)
    lg.print(txt, 8, 8)
end