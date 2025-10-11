periphemu.create("front", "monitor")

local db_info = require("db_info")
local display = require("display")
local physics = require("physics")

local MONITOR = peripheral.find("monitor")
MONITOR.clear()

local mouse_x, mouse_y

local function input_listener()
    while true do _, _, mouse_x, mouse_y = os.pullEvent("monitor_touch") end
end

local function round(n) return math.floor(n + 0.5) end

local function main()
    local fg = colours.toBlit(colours.white)
    local bg = colours.toBlit(colours.blue)

    -- Determine monitor resolution
    local mw, mh = MONITOR.getSize()

    -- Virtual display (full resolution)
    local cv = display.canvas(mw * 2, mh * 3, fg, bg)
    local pm = physics.particle_manager().create(100, cv.w, cv.h)

    -- Actual display output (downscaled resolution)
    local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)
    local wx, wy = win.getPosition()

    while true do
        local t1 = os.epoch("utc")

        win.setVisible(false)
        win.clear()
        cv.clear()

        -- Adjust play area if monitor changes size.
        mw, mh = MONITOR.getSize()
        if mw * 2 * mh * 3 ~= cv.w * cv.h then
            cv.mark = {}
            cv.w, cv.h = mw * 2, mh * 3
            pm.w, pm.h = cv.w, cv.h
            win.reposition(wx, wy, mw, mh)
        end

        -- In case window is not at 1, 1.
        local rx, ry
        if mouse_x and mouse_y then
            rx = (mouse_x - wx + 1) * 2
            ry = (mouse_y - wy + 1) * 3
        end

        pm.update(rx, ry)
        for i = 1, #pm.particles do
            local p = pm.particles[i]
            display.draw_circle(cv, round(p.x), round(p.y), p.r * 2)
        end
        mouse_x, mouse_y = nil, nil

        display.blit_canvas(win, cv)
        win.setVisible(true)

        term.clear()
        print(db_info.get_frame_time(os.epoch("utc") - t1))
        print(db_info.get_mem())

        os.sleep(0.05)
    end
end

parallel.waitForAny(main, input_listener)
