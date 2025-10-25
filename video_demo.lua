periphemu.create("front", "monitor")

local db_info = require("lib.db_info")
local display = require("lib.display")
local media = require("lib.media")

local MONITOR = peripheral.find("monitor")
local VIDEO_PATH = shell.resolve("./media/water_144")

local reader = media.encoded_video_reader(VIDEO_PATH)
local cv = display.canvas(reader.width, reader.height, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

while true do
    local t1 = os.epoch("utc")

    win.setVisible(false)
    cv.clear()
    local pixels, palette = reader.next_frame()
    if not (pixels and palette) then
        reader.restart()
        pixels, palette = reader.next_frame()
    end
    for i, ci in ipairs(media.rgba_to_cc_palette_idxs(pixels, palette)) do
        cv.pixels[i] = colours.toBlit(2 ^ ci)
    end
    display.blit_canvas(win, cv)
    win.setVisible(true)
    -- HAS to be after win.setVisible(true) for some reason. Otherwise, you'll get
    -- flickering and completely wrong colours (using the default palette).
    media.apply_cc_palette(MONITOR, palette)

    local t2 = os.epoch("utc")
    term.clear()
    print(db_info.get_frame_time(t2 - t1))
    print(db_info.get_mem())

    os.sleep(0.05)
end
