local lang = require "lan"
local embarrasingextrainfodisplayedquestionmark = false
return {
    onPlayerInteract = function (self)
        self:say(lang.deertransport_01)
        if embarrasingextrainfodisplayedquestionmark then return end
        self:say(lang.deertransport_02)
        self:say(lang.deertransport_03)
        embarrasingextrainfodisplayedquestionmark = true
    end
}