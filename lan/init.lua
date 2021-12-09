local log = require("lib.log")

local current = require("lan.en")
local languages = {}
print("")

local lang = setmetatable({
    setLanguageByCode = function (code)
        local changed 
        for k, v in pairs(languages) do
            if v.code == code then
                current = v
                log.info("Setting game language to '%s'", v.name)
                changed = true
                break
            end
        end
        if not changed then
            log.error("Couldnt find language of code '%s', defaulting to english :(\n", code)
        end
    end,

    scan = function()
        languages = {}
        for k, v in ipairs(love.filesystem.getDirectoryItems("lan")) do
            if v=="init.lua" then goto continue end
        
            log.info("Loading language from '%s'", v)
            local lang = require("lan."..v:sub(1, #v-4))
            log.assert(type(lang)=="table", "file '%s' wasnt a valid language file, table expected got %s!", v, type(lang))
            log.assert(type(lang.name)=="string", "name property expected to be string, got %s!", type(lang.name))
            log.assert(type(lang.code)=="string", "code property expected to be string, got %s!", type(lang.code))
            languages[v] = lang
        
            ::continue::
        end
    end
}, {
    __index = function(self, k)
        return current[k] or current.no_string or "ERROR: NO STRING FOUND :("
    end
})

return lang