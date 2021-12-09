local lang = require "lan"
return {
    onPlayerInteract = function(self)
        self:say(lang.clonegoat_b_01)
        self:say(lang.clonegoat_b_02)
        self:say(lang.clonegoat_b_03)
        self:say(lang.clonegoat_b_04)

        self:move(-50, 0, 1)
        
        self.destroy = true
    end
}