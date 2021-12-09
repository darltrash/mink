local script = {}
local lang = require("lan")

script.onPlayerInteract = function (self)
    self:say(lang.mrflower000_01)
    self:say(lang.mrflower000_02)
    
    script.onPlayerInteract = function (self)
        self.scaleY = 0.8
        self.offsetY = 32-(32 * 0.9)
        self:say(lang.mrflower000_03)

        script.onPlayerInteract = function (self)
            self.scaleY = 0.7
            self.offsetY = 32-(32*0.85)
            self:say(lang.mrflower000_04)
            
        end
    end
end
return script