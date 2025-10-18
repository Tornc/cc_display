local video = {}

local function read_u16_be(f)
    local b1, b2 = f.read(2):byte(1, 2)
    return bit32.lshift(b1, 8) + b2
end

local function read_u32_be(f)
    local b1, b2, b3, b4 = f.read(4):byte(1, 4)
    return bit32.lshift(b1, 24) + bit32.lshift(b2, 16) + bit32.lshift(b3, 8) + b4
end

function video.encoded_video_reader(file_path)
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

return video
