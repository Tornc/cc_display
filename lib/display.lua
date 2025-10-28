local display = {}

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
    for i = 1, self.w * self.h do self.pixels[i] = self.bg end

    function self.clear()
        for i = 1, self.w * self.h do self.pixels[i] = self.bg end
    end

    function self.put_pixel(x, y, col)
        if x < 1 or x > self.w or y < 1 or y > self.h then return end
        self.pixels[(y - 1) * self.w + x] = col
    end

    --- https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
    function self.draw_line(x1, y1, x2, y2, col)
        local dx = math.abs(x2 - x1)
        local sx = x1 < x2 and 1 or -1
        local dy = -math.abs(y2 - y1)
        local sy = y1 < y2 and 1 or -1
        local err = dx + dy

        local put = self.put_pixel
        while true do
            put(x1, y1, col)
            local err2 = 2 * err
            if err2 >= dy then
                if x1 == x2 then break end
                err = err + dy
                x1 = x1 + sx
            end
            if err2 <= dx then
                if y1 == y2 then break end
                err = err + dx
                y1 = y1 + sy
            end
        end
    end

    --- This is a hollow circle.
    function self.draw_circle(cx, cy, r, col)
        local x = 0
        local y = r
        local p = 1 - r
        local put = self.put_pixel

        while x <= y do
            put(cx + x, cy + y, col)
            put(cx - x, cy + y, col)
            put(cx + x, cy - y, col)
            put(cx - x, cy - y, col)
            put(cx + y, cy + x, col)
            put(cx - y, cy + x, col)
            put(cx + y, cy - x, col)
            put(cx - y, cy - x, col)

            x = x + 1
            if p < 0 then
                p = p + 2 * x + 1
            else
                y = y - 1
                p = p + 2 * (x - y) + 1
            end
        end
    end

    function self.fill(x, y, width, height, col)
        local xs, xe = math.max(x, 1), math.min(x + width - 1, self.w)
        local ys, ye = math.max(y, 1), math.min(y + height - 1, self.h)
        for _y = ys, ye do
            local y_off = (_y - 1) * self.w
            for _x = xs, xe do
                self.pixels[y_off + _x] = col
            end
        end
    end

    --- @param bitmap table<boolean> `false` for transparency.
    --- @param width integer Every row must be equal in length.
    function self.blit_bitmap(bitmap, width, x, y, col)
        local height = #bitmap / width
        local xs, xe = math.max(x, 1), math.min(x + width - 1, self.w)
        local ys, ye = math.max(y, 1), math.min(y + height - 1, self.h)
        for _y = ys, ye do
            local src_y = _y - y + 1
            for _x = xs, xe do
                local src_x = _x - x + 1
                if bitmap[(src_y - 1) * width + src_x] then
                    self.pixels[(_y - 1) * self.w + _x] = col
                end
            end
        end
    end

    --- @param map table<string> `" "` for transparency.
    --- @param width integer Every row must be equal in length.
    function self.blit_map(map, width, x, y)
        local height = #map / width
        local xs, xe = math.max(x, 1), math.min(x + width - 1, self.w)
        local ys, ye = math.max(y, 1), math.min(y + height - 1, self.h)
        for _y = ys, ye do
            local src_y = _y - y + 1
            for _x = xs, xe do
                local src_x = _x - x + 1
                local px = map[(src_y - 1) * width + src_x]
                if px ~= " " then self.pixels[(_y - 1) * self.w + _x] = px end
            end
        end
    end

    return self
end

--- @param cv Canvas
--- @param x integer?
--- @param y integer?
function display.blit_canvas(win, cv, x, y)
    assert(cv.w % 2 == 0, cv.w .. " not multiple of 2.")
    assert(cv.h % 3 == 0, cv.h .. " not multiple of 3.")

    -- Location of canvas, from top-left corner.
    x = x and x or 1
    y = y and y or 1

    -- Actual width, height
    local aw, ah = cv.w / 2, cv.h / 3
    local cvw, cvp = cv.w, cv.pixels

    for _y = 1, ah do
        local chrs = {}
        local tcs = {}
        local bgcs = {}

        for _x = 1, aw do
            local i = ((_y - 1) * 3 * cvw) + ((_x - 1) * 2) + 1

            local c1 = cvp[i]                 -- top-left
            local c2 = cvp[i + 1]             -- top-right
            local c3 = cvp[i + cvw]           -- middle-left
            local c4 = cvp[i + cvw + 1]       -- middle-right
            local c5 = cvp[i + (2 * cvw)]     -- bottom-left
            local c6 = cvp[i + (2 * cvw) + 1] -- bottom-right

            chrs[_x], tcs[_x], bgcs[_x] = shrink_pixels_2x3(c1, c2, c3, c4, c5, c6)
        end
        -- Do NOT blit separately for every pixel; it will cause massive stutters!
        win.setCursorPos(x, y + _y - 1)
        win.blit(table.concat(chrs), table.concat(tcs), table.concat(bgcs))
    end
end

return display
