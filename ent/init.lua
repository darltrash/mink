local log = require "lib.log"
local lume = require "lib.lume"

local preset = {
    x = 0, y = 0, vx = 0, vy = 0, impactX = 0, impactY = 0, impact = 0, scaleX = 1, tooltipAlpha = 0
}
local entities = { "player", "particle", "boombox", "doggo", "destructable", "dust", "npc" }
for _, v in ipairs(entities) do
    log.info("Trying to load ent/%s.lua", v)
    local a = lume.extend(require("ent."..v), preset)
    a.__name = v
    entities[v] = a
end

return entities