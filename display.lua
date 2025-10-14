local display = {}

local CIRCLE = {
    [2] = {
        true, true,
        true, true
    },
    [3] = {
        true, true, true,
        true, true, true,
        true, true, true,
    },
    [4] = {
        false, true, true, false,
        true, true, true, true,
        true, true, true, true,
        false, true, true, false,
    },
    [5] = {
        false, true, true, true, false,
        true, true, true, true, true,
        true, true, true, true, true,
        true, true, true, true, true,
        false, true, true, true, false,
    },
    [6] = {
        false, true, true, true, true, false,
        true, true, true, true, true, true,
        true, true, true, true, true, true,
        true, true, true, true, true, true,
        true, true, true, true, true, true,
        false, true, true, true, true, false,
    },
    [7] = {
        false, false, true, true, true, false, false,
        false, true, true, true, true, true, false,
        true, true, true, true, true, true, true,
        true, true, true, true, true, true, true,
        true, true, true, true, true, true, true,
        false, true, true, true, true, true, false,
        false, false, true, true, true, false, false,
    }
}

--- I was **this** close to brute-force mapping all 64 combinations by hand.
--- My saviour: https://github.com/exerro/ccgl/blob/master/src/functions/texture_subpixel_convert.lua
local function shrink_pixels_2x3(b1, b2, b3, b4, b5, b6)
    local count =
        (b1 and 1 or 0) +
        (b2 and 1 or 0) +
        (b3 and 1 or 0) +
        (b4 and 1 or 0) +
        (b5 and 1 or 0) +
        (b6 and 1 or 0)

    if count == 0 then return 0, false end
    if count == 6 then return 0, true end

    local swap = count >= 3
    -- Special case for the last bit
    if b6 ~= swap then swap = not swap end

    local ch = 128
    if b1 ~= swap then ch = ch + 1 end
    if b2 ~= swap then ch = ch + 2 end
    if b3 ~= swap then ch = ch + 4 end
    if b4 ~= swap then ch = ch + 8 end
    if b5 ~= swap then ch = ch + 16 end
    return ch, swap
end

function display.canvas(w, h, fg, bg)
    --- @class Canvas
    local self = {}
    self.w = w
    self.h = h
    self.fg = fg
    self.bg = bg

    self.frame = 0
    self.mark = {}

    function self.clear()
        self.frame = self.frame + 1
    end

    function self.put(x, y)
        if x < 1 or x > self.w or y < 1 or y > self.h then return end
        self.mark[(y - 1) * self.w + x] = self.frame
    end

    function self.is_set(i)
        return self.mark[i] == self.frame
    end

    return self
end

function display.blit_canvas(win, cv)
    assert(cv.w % 2 == 0, cv.w .. " not multiple of 2.")
    assert(cv.h % 3 == 0, cv.h .. " not multiple of 3.")

    -- Actual width, height
    local aw, ah = cv.w / 2, cv.h / 3
    local cvw, cvfg, cvbg = cv.w, cv.fg, cv.bg
    local isset = cv.is_set --- @type function

    for y = 1, ah do
        local chrs = {}
        local tcs = {}
        local bgcs = {}

        for x = 1, aw do
            local i = ((y - 1) * 3 * cvw) + ((x - 1) * 2) + 1

            local b1 = isset(i)                 -- top-left
            local b2 = isset(i + 1)             -- top-right
            local b3 = isset(i + cvw)           -- middle-left
            local b4 = isset(i + cvw + 1)       -- middle-right
            local b5 = isset(i + (2 * cvw))     -- bottom-left
            local b6 = isset(i + (2 * cvw) + 1) -- bottom-right

            local ch, sw = shrink_pixels_2x3(b1, b2, b3, b4, b5, b6)
            chrs[x] = string.char(ch)
            tcs[x] = sw and cvbg or cvfg
            bgcs[x] = sw and cvfg or cvbg
        end
        -- Do NOT blit separately for every pixel; it will cause massive stutters!
        win.setCursorPos(1, y)
        win.blit(table.concat(chrs), table.concat(tcs), table.concat(bgcs))
    end
end

function display.draw_circle(canvas, x, y, diameter)
    if diameter == 1 then
        canvas.put(x, y); return
    end

    local o_x = x - math.floor(diameter / 2) - 1
    local o_y = y - math.floor(diameter / 2) - 1

    local bm = CIRCLE[diameter]
    local put = canvas.put --- @type function
    for _y = 1, diameter do
        local y_off = o_y + _y
        for _x = 1, diameter do
            if bm[(_y - 1) * diameter + _x] then
                put(o_x + _x, y_off)
            end
        end
    end
end

return display
