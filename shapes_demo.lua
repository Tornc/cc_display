periphemu.create("front", "monitor")
local display = require("lib.display")

local MONITOR = peripheral.find("monitor")
local mw, mh = MONITOR.getSize()
local cv = display.canvas(mw * 2, mh * 3, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

cv.clear()

cv.draw_line(2, 18, 20, 25, colours.toBlit(colours.green))
cv.draw_line(10, 15, 1, 30, colours.toBlit(colours.yellow))
cv.draw_circle(25, 15, 9, colours.toBlit(colours.lightBlue))
cv.fill(40, 2, 20, 10, colours.toBlit(colours.red))
cv.blit_bitmap({
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
}, 9, 1, 1, colours.toBlit(colours.purple))
cv.blit_map({
    " ", " ", "4", "4", "4", "4", " ", " ",
    " ", "4", "4", "4", "f", "4", "4", " ",
    "4", "4", "4", "4", "4", "4", "4", " ",
    "4", "4", "4", "4", "4", "4", "1", "1",
    " ", "4", "4", "4", "4", "4", "1", "1",
    " ", " ", "4", "4", "4", "4", " ", " ",
}, 8, 40, 15)

display.blit_canvas(win, cv)
