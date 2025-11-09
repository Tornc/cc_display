local media = {}

local function read_u16_be(f)
    local b1, b2 = f.read(2):byte(1, 2)
    return b1 * 256 + b2
end

local function read_u32_be(f)
    local b1, b2, b3, b4 = f.read(4):byte(1, 4)
    return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
end

function media.encoded_video_reader(file_path)
    --- @class EncodedVideoReader
    local self = {}
    self.file = fs.open(file_path .. ".ev", "rb")
    self.width = read_u16_be(self.file)
    self.height = read_u16_be(self.file)
    self.frame_count = read_u32_be(self.file)
    self.frames_read = 0

    self._palette = {}
    self._pixels = {}

    function self.next_frame()
        if self.frames_read >= self.frame_count then return nil, nil end

        local palette_size = read_u16_be(self.file)
        local palette = self._palette
        for i = 1, palette_size do
            local pb1, pb2, pb3, _ = self.file.read(4):byte(1, 4)
            palette[i] = pb1 * 65536 + pb2 * 256 + pb3
        end

        local rle_len = read_u32_be(self.file)
        local data = self.file.read(rle_len * 2)
        local pixels = self._pixels
        local pos, idx = 1, 1

        while pos < #data do
            local cidx = data:byte(pos)
            local run = data:byte(pos + 1)
            local colour = palette[cidx + 1]
            for _ = 1, run do
                pixels[idx] = colour
                idx = idx + 1
            end
            pos = pos + 2
        end

        self.frames_read = self.frames_read + 1
        return pixels, palette
    end

    function self.restart()
        self.file.seek("set", 8)
        self.frames_read = 0
    end

    function self.close()
        self.file.close()
    end

    return self
end

function media.read_encoded_image(file_path)
    local file = fs.open(file_path .. ".ei", "rb")
    local width = read_u32_be(file)
    local height = read_u32_be(file)

    local palette_size = read_u16_be(file)
    local palette = {}
    for i = 1, palette_size do
        local pb1, pb2, pb3, _ = file.read(4):byte(1, 4)
        palette[i] = pb1 * 65536 + pb2 * 256 + pb3
    end

    local rle_len = read_u32_be(file)
    local data = file.read(rle_len * 2)
    local pixels = {}
    local pos, idx = 1, 1
    while pos < #data do
        local cidx = data:byte(pos)
        local run = data:byte(pos + 1)
        local colour = palette[cidx + 1]
        for _ = 1, run do
            pixels[idx] = colour
            idx = idx + 1
        end
        pos = pos + 2
    end
    file.close()
    return pixels, palette, width, height
end

--- @param canvas Canvas
function media.blit_frame(canvas, pixels, palette)
    local blit_map = {}
    for i = 1, #palette do
        blit_map[palette[i]] = colours.toBlit(2 ^ (i - 1))
    end
    local pix, blit = pixels, canvas.pixels
    for i = 1, #pix do
        blit[i] = blit_map[pix[i]]
    end
end

function media.apply_cc_palette(screen, palette)
    for i = 1, #palette do screen.setPaletteColour(2 ^ (i - 1), palette[i]) end
end

return media
