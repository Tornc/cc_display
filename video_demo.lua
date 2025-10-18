periphemu.create("front", "monitor")

local db_info = require("lib.db_info")
local display = require("lib.display")
local video = require("lib.video")

local MONITOR = peripheral.find("monitor")
-- Change this; I'm just suffering from the fact that everything starts from root.
local VIDEO_PATH = "./cc_display/media/water_144"

local reader = video.encoded_video_reader(VIDEO_PATH)
local mw, mh = reader.width / 2, reader.height / 3 -- CraftOS default is 51, 19
local cv = display.canvas(mw * 2, mh * 3, colours.toBlit(colours.black))
local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)

while true do
    local t1 = os.epoch("utc")

    win.setVisible(false)
    cv.clear()
    local frame, palette = reader.next_frame()
    if not (frame and palette) then
        reader.restart()
        frame, palette = reader.next_frame()
    end
    for i, ci in ipairs(video.rgba_to_palette_indices(frame, palette)) do
        cv.pixels[i] = colours.toBlit(2 ^ ci)
    end
    display.blit_canvas(win, cv)
    win.setVisible(true)
    -- HAS to be after win.setVisible(true) for some reason. Otherwise, you'll get
    -- flickering and completely wrong colours (using the default palette).
    video.apply_palette(MONITOR, palette)

    local t2 = os.epoch("utc")
    term.clear()
    print(db_info.get_frame_time(t2 - t1))
    print(db_info.get_mem())

    os.sleep(0.05)
end
