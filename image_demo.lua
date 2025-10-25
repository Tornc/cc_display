periphemu.create("front", "monitor")

local display = require("lib.display")
local media = require("lib.media")

local MONITOR = peripheral.find("monitor")
local IMAGE_PATH = shell.resolve("./media/toy")

local pixels, palette, width, height = media.read_encoded_image(IMAGE_PATH)
local cv = display.canvas(width, height, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

cv.clear()
for i, ci in ipairs(media.rgba_to_cc_palette_idxs(pixels, palette)) do
    cv.pixels[i] = colours.toBlit(2 ^ ci)
end

display.blit_canvas(win, cv)
media.apply_cc_palette(MONITOR, palette)
