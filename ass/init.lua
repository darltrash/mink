local toml = require "lib.toml"
local log  = require "lib.log"
local lume = require "lib.lume"
lg.setDefaultFilter("nearest", "nearest")

--[=[return {
    fonts = {
        main = lg.font("ass/fnt_PixeloidSans.ttf",      9),
        bold = lg.font("ass/fnt_PixeloidSans-Bold.ttf", 9),
        mono = lg.font("ass/fnt_PixeloidMono.ttf",      9)
    },

    shaders = {
        background = lg.shader[[
            #ifdef VERTEX
            vec4 position( mat4 transform_projection, vec4 vertex_position )
            {
                return transform_projection * vertex_position;
            }
            #endif

            #ifdef PIXEL
            uniform vec4 color1;
            uniform vec4 color2;

            vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
            {
                return mix(color1, color2, texture_coords.y);
            }
            #endif
        ]]
    },

    atlases = {
        blank = {
            texture = lg.image("ass/spr_blank.png"),
            w = 1, h = 1
        },

        tileset0 = {
            texture = lg.image("ass/atl_test.png"),
            w = 8, h = 8
        },

        spritesheet0 = {
            texture = lg.image("ass/atl_test2.png"),
            w = 8, h = 8
        },

        player0 = {
            texture = lg.image("ass/atl_player.png"),
            w = 32, h = 32
        },

        test_boombox = {
            texture = lg.image("ass/atl_boombox.png"),
            w = 32, h = 32
        },

        dog = {
            texture = lg.image("ass/atl_dog.png"),
            w = 32, h = 32
        },

        dust = {
            texture = lg.image("ass/atl_dust0.png"),
            w = 32, h = 32
        }
    },

    sounds = {
        footsteps = la.source("ass/snd_footsteps.wav", "static"),
        plink = la.source("ass/snd_plink.wav", "static"),
        scream = la.source("ass/snd_scream.wav", "static"),
        bark = la.source("ass/snd_dog.wav", "static")
    },

    music = {
        purple = la.source("ass/mus_purpleloop.mp3", "stream"),
        hourstraight = la.source("ass/mus_hourstraight.mp3", "stream")
    }
}]=]

log.info("Attempting to load assets from ass/manifest.toml")
local data, err = lf.read("ass/manifest.toml")
log.assert(data, err)

data = toml.parse(data)

for key, font in pairs(data.fonts or {}) do
    log.info("Trying to load font '%s'", key)
    log.assert(type(font.file)=="string", "file property expected to be string, got '%s'!", type(font.file))
    log.assert(type(font.size)=="number" or font.size=="max", "size property expected to be number or 'max', got '%s', '%s'!", type(font.size), font.size)

    data.fonts[key] = lg.font(font.file, font.size == "max" and 100 or font.size)
end

for key, shader in pairs(data.shaders or {}) do
    log.info("Trying to load shader '%s'", key)
    log.assert(type(shader.file)=="string", "file property expected to be string, got '%s'!", type(shader.file))

    data.shaders[key] = lg.shader(shader.file)
end

local _print = function (font, text, x, y, hicolor, scale, limit)
    local scale = scale or 1
    local orcolor = {lg.getColor()}
    local x_, y_ = x, y
    local highlight = false
    local count = 1
    for c in text:gmatch(".") do
        if count > (limit or #text) then break end
        if c == "\n" then
            x_ = x
            y_ = y_ + font.h * scale
        elseif c == "*" then
            highlight = not highlight
            lg.setColor(orcolor)
            if highlight and hicolor then
                lg.setColor(hicolor)
            end
        else
            if font.map[c] then
                lg.draw(font.texture, font.map[c], x_, y_, 0, scale)
            end
            x_ = x_ + font.w*scale
        end
        count = count + 1
    end
    lg.setColor(orcolor)
end

local _length = lume.memoize(function(font, text)
    local x, y = 0, 0
    local mx, my = 0, 0
    for c in text:gmatch(".") do
        if c == "\n" then
            y = y + 1
            x = 0
        else
            x = x + 1
        end
        mx, my = math.max(mx, x), math.max(my, y)
    end
    return mx, my
end)

for key, atlas in pairs(data.atlases or {}) do
    log.info("Trying to load atlas '%s'", key)
    log.assert(type(atlas.file)=="string", "file property expected to be string, got '%s'!", type(atlas.file))
    log.assert(type(atlas.width)=="number", "width property expected to be number, got '%s'!", type(atlas.width))
    log.assert(type(atlas.height)=="number", "height property expected to be number, got '%s'!", type(atlas.height))
    log.assert(type(atlas.map or "")=="string", "map property expected to be string or nil, got %s", type(atlas.map))

    data.atlases[key] = {
        texture = lg.image(atlas.file),
        w = atlas.width,
        h = atlas.height
    }

    if atlas.map then
        local map = {}
        local atl = data.atlases[key]
        local x, y = 0, 0
        for c in atlas.map:gmatch(".") do
            if (x*atl.w)>atl.texture:getWidth() then
                x = 0
                y = y + 1
            end
            map[c] = lg.quad(x*atl.w, y*atl.h, atl.w, atl.h, atl.texture:getWidth(), atl.texture:getHeight())
            x = x + 1
        end
        atl.map = map
        atl.print = _print
        atl.lenght = _length
    end
end

for key, sound in pairs(data.sounds or {}) do
    log.info("Trying to load sound '%s'", key)
    log.assert(type(sound.file)=="string", "file property expected to be string, got '%s'!", type(sound.file))

    data.sounds[key] = la.source(sound.file, "static")
end

for key, song in pairs(data.music or {}) do
    log.info("Trying to load sound '%s'", key)
    log.assert(type(song.file)=="string", "file property expected to be string, got '%s'!", type(song.file))

    data.music[key] = la.source(song.file, "stream")
end

print("")

return data