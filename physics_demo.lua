periphemu.create("front", "monitor")

local display = require("lib.display")
local physics = require("lib.physics")

local MONITOR = peripheral.find("monitor")
local mouse_x, mouse_y

local CIRCLE = {
    [3] = {
        true, true, true,
        true, true, true,
        true, true, true,
    },
    [5] = {
        false, true, true, true, false,
        true, true, true, true, true,
        true, true, true, true, true,
        true, true, true, true, true,
        false, true, true, true, false,
    },
    [7] = {
        false, false, true, true, true, false, false,
        false, true, true, true, true, true, false,
        true, true, true, true, true, true, true,
        true, true, true, true, true, true, true,
        true, true, true, true, true, true, true,
        false, true, true, true, true, true, false,
        false, false, true, true, true, false, false,
    }
}

local function input_listener()
    while true do _, _, mouse_x, mouse_y = os.pullEvent("monitor_touch") end
end

local function round(n) return math.floor(n + 0.5) end

local function main()
    -- Determine monitor resolution
    local mw, mh = MONITOR.getSize()
    -- Virtual display (full resolution)
    local cv = display.canvas(mw * 2, mh * 3, colours.toBlit(colours.black))
    local pm = physics.particle_manager(250, 15, cv.w, cv.h)
    -- Actual display output (downscaled resolution)
    local win = window.create(MONITOR, 1, 1, cv.w / 2, cv.h / 3)
    local wx, wy = win.getPosition()

    while true do
        win.setVisible(false)
        cv.clear()

        -- Adjust play area if monitor changes size.
        mw, mh = MONITOR.getSize()
        if mw * 2 * mh * 3 ~= cv.w * cv.h then
            cv.w, cv.h = mw * 2, mh * 3
            cv.clear()
            pm.w, pm.h = cv.w, cv.h
            win.reposition(wx, wy, mw, mh)
        end

        -- In case window is not at 1, 1. Also account for subpixels being smaller.
        local rx, ry
        if mouse_x and mouse_y then
            rx = (mouse_x - wx + 1) * 2
            ry = (mouse_y - wy + 1) * 3
        end

        pm.update(rx, ry)
        for i = 1, #pm.particles do
            local p = pm.particles[i]
            local size = p.r * 2
            if size == 1 then
                cv.put_pixel(round(p.x), round(p.y), p.c)
            else
                local o_x = p.x - math.floor(p.r) - 1
                local o_y = p.y - math.floor(p.r) - 1
                cv.blit_bitmap(CIRCLE[size], size, round(o_x), round(o_y), p.c)
            end
        end
        mouse_x, mouse_y = nil, nil

        display.blit_canvas(win, cv)
        win.setVisible(true)

        os.sleep(0.05)
    end
end

parallel.waitForAny(main, input_listener)

--- @TODO:
--- 1. display on term instead of monitor
---    use mut for debug
--- 2. particle: ax, ay --> move() vx, vy += ax (0), ay (grav)
--- 3. N-body sim on top of collision
