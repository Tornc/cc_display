periphemu.create("front", "monitor")
local display = require("lib.display")

local MONITOR = peripheral.find("monitor")
local mw, mh = MONITOR.getSize()
local cv = display.canvas(mw * 2, mh * 3, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

cv.clear()

cv.draw_line(2, 18, 8, 24, colours.toBlit(colours.green))
cv.draw_line(10, 4, 1, 18, colours.toBlit(colours.yellow))
cv.draw_circle(25, 15, 9, colours.toBlit(colours.lightBlue))
cv.fill(40, 10, 20, 10, colours.toBlit(colours.red))
cv.blit({
    true, true, true, true,
    true, false, false, true,
    true, false, false, true,
    true, true, true, true,
}, 1, 1, 4, colours.toBlit(colours.purple))

display.blit_canvas(win, cv)
