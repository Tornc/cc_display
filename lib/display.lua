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

--- Not used, but kept as I just really like it.
local function shrink_bitmap_2x3(b1, b2, b3, b4, b5, b6)
    local count =
        (b1 and 1 or 0) +
        (b2 and 1 or 0) +
        (b3 and 1 or 0) +
        (b4 and 1 or 0) +
        (b5 and 1 or 0) +
        (b6 and 1 or 0)

    if count == 0 then return " ", false end
    if count == 6 then return " ", true end

    local swap = count >= 3
    if b6 ~= swap then swap = not swap end -- Special case for the last bit

    local ch = 128
    if b1 ~= swap then ch = ch + 1 end
    if b2 ~= swap then ch = ch + 2 end
    if b3 ~= swap then ch = ch + 4 end
    if b4 ~= swap then ch = ch + 8 end
    if b5 ~= swap then ch = ch + 16 end
    return string.char(ch), swap
end

--- I was **this** close to brute-force mapping all 64 combinations by hand.
--- My saviour: https://github.com/exerro/ccgl/blob/master/src/functions/texture_subpixel_convert.lua
local function shrink_pixels_2x3(c1, c2, c3, c4, c5, c6)
    if c1 == c2 and c2 == c3 and c3 == c4 and c4 == c5 and c5 == c6 then
        return " ", c1, c1
    end

    local colour_counts = {}
    for i = 1, 6 do
        local col = select(i, c1, c2, c3, c4, c5, c6)
        colour_counts[col] = (colour_counts[col] or 0) + 1
    end

    local major_col, minor_col
    local major_count, minor_count = 0, 0
    for col, count in pairs(colour_counts) do
        if count > major_count then
            minor_col, minor_count = major_col, major_count
            major_col, major_count = col, count
        elseif count > minor_count then
            minor_col, minor_count = col, count
        end
    end

    if major_count >= 3 then major_col, minor_col = minor_col, major_col end
    if c6 ~= minor_col then major_col, minor_col = minor_col, major_col end

    local ch = 128
    if c1 ~= minor_col then ch = ch + 1 end
    if c2 ~= minor_col then ch = ch + 2 end
    if c3 ~= minor_col then ch = ch + 4 end
    if c4 ~= minor_col then ch = ch + 8 end
    if c5 ~= minor_col then ch = ch + 16 end
    return string.char(ch), major_col, minor_col
end

function display.canvas(w, h, bg)
    --- @class Canvas
    local self = {}
    self.w = w
    self.h = h
    self.bg = bg
    self.pixels = {}

    function self.clear()
        for i = 1, self.w * self.h do self.pixels[i] = self.bg end
    end

    function self.set_pixel(x, y, col)
        if x < 1 or x > self.w or y < 1 or y > self.h then return end
        self.pixels[(y - 1) * self.w + x] = col
    end

    return self
end

function display.blit_canvas(win, cv)
    assert(cv.w % 2 == 0, cv.w .. " not multiple of 2.")
    assert(cv.h % 3 == 0, cv.h .. " not multiple of 3.")

    -- Actual width, height
    local aw, ah = cv.w / 2, cv.h / 3
    local cvw, cvp = cv.w, cv.pixels

    for y = 1, ah do
        local chrs = {}
        local tcs = {}
        local bgcs = {}

        for x = 1, aw do
            local i = ((y - 1) * 3 * cvw) + ((x - 1) * 2) + 1

            local c1 = cvp[i]                 -- top-left
            local c2 = cvp[i + 1]             -- top-right
            local c3 = cvp[i + cvw]           -- middle-left
            local c4 = cvp[i + cvw + 1]       -- middle-right
            local c5 = cvp[i + (2 * cvw)]     -- bottom-left
            local c6 = cvp[i + (2 * cvw) + 1] -- bottom-right

            chrs[x], tcs[x], bgcs[x] = shrink_pixels_2x3(c1, c2, c3, c4, c5, c6)
        end
        -- Do NOT blit separately for every pixel; it will cause massive stutters!
        win.setCursorPos(1, y)
        win.blit(table.concat(chrs), table.concat(tcs), table.concat(bgcs))
    end
end

function display.draw_circle(canvas, x, y, diameter, col)
    if diameter == 1 then
        canvas.set_pixel(x, y, col); return
    end

    local o_x = x - math.floor(diameter / 2) - 1
    local o_y = y - math.floor(diameter / 2) - 1

    local bm = CIRCLE[diameter]
    local set_pixel = canvas.set_pixel --- @type function
    for _y = 1, diameter do
        local y_off = o_y + _y
        for _x = 1, diameter do
            if bm[(_y - 1) * diameter + _x] then
                set_pixel(o_x + _x, y_off, col)
            end
        end
    end
end

return display
