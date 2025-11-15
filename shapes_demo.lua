periphemu.create("front", "monitor")
local display = require("lib.display")

local MONITOR = peripheral.find("monitor")
local mw, mh = MONITOR.getSize()
local cv = display.canvas(mw * 2, mh * 3, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

local green = colours.toBlit(colours.green)
local yellow = colours.toBlit(colours.yellow)
local light_blue = colours.toBlit(colours.lightBlue)
local red = colours.toBlit(colours.red)
local purple = colours.toBlit(colours.purple)
local pink = colours.toBlit(colours.pink)

local function checkerboard(width, height, size)
    local tex = {}
    local clrs = { "2", "3" }
    for y = 1, height do
        local y_off = (y - 1) * width
        for x = 1, width do
            local block_x = math.floor((x - 1) / size)
            local block_y = math.floor((y - 1) / size)
            local ci = ((block_x + block_y) % 2) + 1
            tex[y_off + x] = clrs[ci]
        end
    end
    return tex
end

cv.clear()

cv.draw_line(13, 2, 1, 25, yellow)
cv.draw_line(2, 12, 20, 21, green)
cv.draw_circle(25, 10, 8, light_blue)
cv.fill(40, 2, 20, 10, red)
cv.blit_bitmap(1, 1, purple, {
    false, false, true, true, true, true, true, false, false,
    false, true, false, false, false, false, false, true, false,
    true, false, true, false, false, false, true, false, true,
    true, false, false, false, false, false, false, false, true,
    true, false, true, false, false, false, true, false, true,
    true, false, false, true, true, true, false, false, true,
    false, true, false, false, false, false, false, true, false,
    false, false, true, true, false, true, true, false, false,
    false, false, false, false, true, false, false, false, false,
    false, false, false, false, true, false, false, false, false,
    false, false, false, false, true, false, false, false, false,
}, 9)
cv.blit_map(38, 15, {
    " ", " ", "4", "4", "4", "4", " ", " ",
    " ", "4", "4", "4", "f", "4", "4", " ",
    "4", "4", "4", "4", "4", "4", "4", " ",
    "4", "4", "4", "4", "4", "4", "4", "1",
    " ", "4", "4", "4", "4", "4", "4", "1",
    " ", " ", "4", "4", "4", "4", " ", " ",
}, 8)
cv.fill_triangle(40, 25, 58, 18, 53, 25, pink)
cv.blit_triangle(
    { 8, 20, 0, 0 },
    { 50, 32, 1, 0 },
    { 10, 30, 0.5, 1 },
    checkerboard(25, 10, 4), 25
)

display.blit_canvas(win, cv)
