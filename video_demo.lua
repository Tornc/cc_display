periphemu.create("front", "monitor")

local bit32 = require("bit32")
local db_info = require("lib.db_info")
local display = require("lib.display")

local MONITOR = peripheral.find("monitor")
-- Change this; I'm just suffering from the fact that everything starts from root.
local VIDEO_PATH = "./cc_phys/media/water_144"

local function read_u16_be(f)
    local b1, b2 = f.read(2):byte(1, 2)
    return bit32.lshift(b1, 8) + b2
end

local function read_u32_be(f)
    local b1, b2, b3, b4 = f.read(4):byte(1, 4)
    return bit32.lshift(b1, 24) + bit32.lshift(b2, 16) + bit32.lshift(b3, 8) + b4
end

local function encoded_video_reader(file_path)
    --- @class EncodedVideoReader
    local self = {}
    self.f = fs.open(file_path .. ".ev", "rb")
    self.width = read_u16_be(self.f)
    self.height = read_u16_be(self.f)
    self.frame_count = read_u32_be(self.f)
    self.frames_read = 0

    function self.next_frame()
        if self.frames_read >= self.frame_count then return nil, nil end

        local palette_size = read_u16_be(self.f)
        local palette = {}
        for _ = 1, palette_size do
            local pb = { self.f.read(4):byte(1, 4) }
            local color = bit32.lshift(pb[1], 16) + bit32.lshift(pb[2], 8) + pb[3]
            palette[#palette + 1] = color
        end

        local rle_len = read_u32_be(self.f)
        local pixels = {}
        for _ = 1, rle_len do
            local ic = { self.f.read(2):byte(1, 2) }
            local color = palette[ic[1] + 1]
            for _ = 1, ic[2] do
                pixels[#pixels + 1] = color
            end
        end

        self.frames_read = self.frames_read + 1
        return pixels, palette
    end

    function self.restart()
        self.f.seek("set", 8)
        self.frames_read = 0
    end

    return self
end

local function apply_palette(screen, palette)
    for i = 1, #palette do screen.setPaletteColor(2 ^ (i - 1), palette[i]) end
end

local function rgba_to_palette_indices(pixels, palette)
    local lookup = {}
    for i = 1, #palette do lookup[palette[i]] = i - 1 end
    local indices = {}
    for i = 1, #pixels do indices[i] = lookup[pixels[i]] end
    return indices
end

local reader = encoded_video_reader(VIDEO_PATH)
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
    local indices = rgba_to_palette_indices(frame, palette)
    for i, ci in ipairs(indices) do
        cv.pixels[i] = colours.toBlit(2 ^ ci)
    end
    display.blit_canvas(win, cv)
    win.setVisible(true)
    -- HAS to be after win.setVisible(true) for some reason. Otherwise, you'll get
    -- flickering and completely wrong colours (using the default palette).
    apply_palette(MONITOR, palette)

    local t2 = os.epoch("utc")
    term.clear()
    print(db_info.get_frame_time(t2 - t1))
    print(db_info.get_mem())

    os.sleep(0.05)
end
