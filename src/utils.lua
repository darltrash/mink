local lume = require "lib.lume"
local assets = require "ass"
return {
    textSize = lume.memoize(function (font, text, font2)
        local cfont = font
        local w, h, ww, hh = 0, cfont:getHeight("X"), 0, 0
        local highlight = false

        for c in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            if c == "\n" then
                h = h + cfont:getHeight("X")
                w = 0
            elseif c == "*" then
                highlight = not highlight
                cfont = highlight and font2 or font
            elseif c == "~" then
            else
                w = w + cfont:getWidth(c)
            end

            ww = math.max(ww, w)
            hh = math.max(hh, h)
        end
        return ww, hh
    end),

    print = function (font, text, x, y, hicolor, scale, limit, font2)
        local scale = scale or 112
        local orcolor = {lg.getColor()}
        lg.setFont(font)
        local cfont = font
        local x_, y_ = x, y
        local highlight = false
        local movey = false
        local count = 1
        for c in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            if count > (limit or 0) then break end
            if c == "\n" then
                x_ = x
                y_ = y_ + cfont:getHeight(c) * scale
            elseif c == "*" then
                highlight = not highlight
                lg.setColor(orcolor)
                cfont = highlight and font2 or font
                lg.setFont(cfont)
                if highlight and hicolor then
                    lg.setColor(hicolor)
                end
            elseif c == "~" then
                movey = not movey
            else
                lg.print(c, x_, y_+(movey and math.sin(count+lt.getTime()*5) or 0), 0, scale)
                x_ = x_ + cfont:getWidth(c)*scale
            end
            count = count + 1
        end
        lg.setColor(orcolor)
    end
}