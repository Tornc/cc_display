periphemu.create("front", "monitor")

local display = require("lib.display")
local media = require("lib.media")

local MONITOR = peripheral.find("monitor")
local IMAGE_PATH = shell.resolve("./media/toy")

local pixels, palette, width, height = media.read_encoded_image(IMAGE_PATH)
local cv = display.canvas(width, height, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

cv.clear()
media.blit_frame(cv, pixels, palette)
media.apply_cc_palette(win, palette)
display.blit_canvas(win, cv)
