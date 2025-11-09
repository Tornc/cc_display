periphemu.create("front", "monitor")

local display = require("lib.display")
local media = require("lib.media")

local MONITOR = peripheral.find("monitor"); MONITOR.setTextScale(0.5)
local VIDEO_PATH = shell.resolve("./media/test_hr")

local reader = media.encoded_video_reader(VIDEO_PATH)
local cv = display.canvas(reader.width, reader.height, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

while true do
    win.setVisible(false)
    cv.clear()
    local pixels, palette = reader.next_frame()
    if not (pixels and palette) then
        reader.close(); break
    end
    media.blit_frame(cv, pixels, palette)
    media.apply_cc_palette(win, palette)
    display.blit_canvas(win, cv)
    win.setVisible(true)

    os.sleep(0.05)
end
