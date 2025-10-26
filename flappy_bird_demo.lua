--- Loosely followed:
--- https://medium.com/@konstanty.koszewski_35161/flappy-bird-clone-in-ruby-961aaaca7443
--- but mine is just plain shittier.

periphemu.create("front", "monitor")
periphemu.create("back", "speaker")

local dfpwm = require("cc.audio.dfpwm")
local display = require("lib.display")

local MONITOR = peripheral.find("monitor")
local SPEAKER = peripheral.find("speaker")

local DECODER = dfpwm.make_decoder()
local POINT_SOUND_PATH = shell.resolve("./media/point")
local DIE_SOUND_PATH = shell.resolve("./media/die")

local jump

local function round(n) return math.floor(n + 0.5) end

local function play_sound(file_path)
    coroutine.resume(coroutine.create(
        function()
            for chunk in io.lines(file_path .. ".dfpwm", 16 * 1024) do
                local buffer = DECODER(chunk)
                while not SPEAKER.playAudio(buffer) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
        end
    ))
end

local function input_listener()
    while true do
        local _, _, _, _ = os.pullEvent("monitor_touch")
        jump = true
    end
end

--- @param cv Canvas
local function bird(cv)
    --- @class Bird
    local self = {}
    self.cv = cv
    self.sprite = {
        " ", " ", "4", "4", "4", "4", " ", " ",
        " ", "4", "4", "4", "f", "4", "4", " ",
        "4", "4", "4", "4", "4", "4", "4", " ",
        "4", "4", "4", "4", "4", "4", "4", "1",
        " ", "4", "4", "4", "4", "4", "4", "1",
        " ", " ", "4", "4", "4", "4", " ", " ",
    }
    self.w = 8
    self.h = 6
    self.r = 3 -- hitcircle, im lazy
    self.x = round(cv.w * 0.05)
    self.y = round(cv.h * 0.5)
    self.g = 0.2
    self.vy = 0

    function self.jump()
        self.vy = self.vy - 2
    end

    function self.move()
        self.vy = self.vy + self.g
        self.y = self.y + self.vy
        self.y = round(self.y)
    end

    function self.fell()
        return self.y + self.h < 1 or self.y - self.h > self.cv.h
    end

    function self.draw()
        self.cv.blit_map(self.sprite, self.w, self.x, self.y)
    end

    return self
end

--- @param cv Canvas
local function pipe_pair(cv)
    --- @class PipePair
    local self = {}
    self.cv = cv
    self.w = 12
    self.h = round(cv.h * 0.05 + math.random(cv.h * 0.4))
    self.gap = round(cv.h * 0.4)
    self.c = colours.toBlit(colours.green)

    self.x = cv.w + self.w
    self.y = 0
    self.vx = 2
    self.already_scored = false

    function self.move()
        self.x = self.x - self.vx
    end

    --- @param brd Bird
    function self.is_scoring(brd)
        if self.already_scored then return end
        self.already_scored = self.x <= brd.x
        return self.already_scored
    end

    --- @param brd Bird
    function self.is_hit(brd)
        local r = brd.r
        local bcx = brd.x + r
        local bcy = brd.y + r
        if bcx - r < self.x or bcx + r > self.x + self.w - 1 then return end
        local in_y_gap = (
            bcy - r >= self.y + self.h and
            bcy + r <= self.y + self.h - 1 + self.gap
        )
        return not in_y_gap
    end

    function self.is_off_screen()
        return self.x + self.w < 1
    end

    function self.draw()
        self.cv.fill(self.x, self.y, self.w, self.h, self.c)
        self.cv.fill(self.x, self.y + self.h + self.gap, self.w, self.cv.h, self.c)
    end

    return self
end

local function restart_game()
    local mw, mh = MONITOR.getSize()
    local cv = display.canvas(mw * 2, mh * 3, colours.toBlit(colours.lightBlue))
    local win = window.create(MONITOR, 1, 1, mw, mh)
    local brd = bird(cv)
    local pipes = {}
    local frames = 0
    local score = 0
    local game_over = false
    jump = false
    return cv, win, mw, mh, brd, pipes, frames, score, game_over
end

local function main()
    local cv, win, mw, mh, brd, pipes, frames, score, game_over = restart_game()

    local dirt_h = math.floor(cv.h * 0.1)
    local dirt_y = cv.h + 1 - dirt_h
    local dirt_col = colours.toBlit(colours.brown)
    local grass_h = math.floor(cv.h * 0.05)
    local grass_y = cv.h + 1 - grass_h - dirt_h
    local grass_col = colours.toBlit(colours.lime)

    while true do
        win.setVisible(false)

        if game_over then
            local game_over_text = "GAME OVER"
            local restart_text = "Click to restart"

            win.setCursorPos(round(mw * 0.5 - #game_over_text / 2 + 1), round(mh * 0.4))
            win.blit(game_over_text, string.rep("0", #game_over_text), string.rep(cv.bg, #game_over_text))
            win.setCursorPos(round(mw * 0.5 - #restart_text / 2), round(mh * 0.6))
            win.blit(restart_text, string.rep("0", #restart_text), string.rep(cv.bg, #restart_text))

            win.setVisible(true)
            os.pullEvent("monitor_touch")
            cv, win, mw, mh, brd, pipes, frames, score, game_over = restart_game()
        end

        cv.clear()

        -- Updating
        if jump then brd.jump() end
        brd.move()
        for _, p in ipairs(pipes) do p.move() end

        -- Drawing
        cv.fill(1, dirt_y, cv.w, dirt_h, dirt_col)
        cv.fill(1, grass_y, cv.w, grass_h, grass_col)
        for _, p in ipairs(pipes) do p.draw() end
        brd.draw()

        -- State management
        if frames % 20 == 0 then table.insert(pipes, pipe_pair(cv)) end
        local is_hit
        if #pipes > 0 then
            if pipes[1].is_scoring(brd) then
                score = score + 1
                play_sound(POINT_SOUND_PATH)
            end
            if pipes[1].is_off_screen() then table.remove(pipes, 1) end
            is_hit = pipes[1].is_hit(brd)
        end

        if is_hit or brd.fell() then
            game_over = true
            play_sound(DIE_SOUND_PATH)
            for _, p in ipairs(pipes) do p.vx = 0 end
            brd.g = 0
            brd.vy = 0
        end

        -- Prepare for next frame
        jump = false
        frames = frames + 1

        display.blit_canvas(win, cv)
        local text = tostring(score)
        win.setCursorPos(round(mw * 0.5), round(mh * 0.2))
        win.blit(text, string.rep("0", #text), string.rep(cv.bg, #text))
        win.setVisible(true)

        os.sleep(0.05)
    end
end

parallel.waitForAny(main, input_listener)

--- @TODO: cleanup
