local db_info = {}

local fps_values = {}

local function round(n) return math.floor(n + 0.5) end

function db_info.get_fps(dt)
    local fps = round(1000 / dt)
    table.insert(fps_values, fps)
    if #fps_values > 100 then table.remove(fps_values, 1) end
    local avg, low_1

    local total = 0
    for i = 1, #fps_values do
        total = total + fps_values[i]
    end
    avg = round(total / #fps_values)

    local sorted = {}
    for i, v in ipairs(fps_values) do sorted[i] = v end
    table.sort(sorted)
    low_1 = sorted[math.max(1, math.floor(#sorted * 0.01))]

    return
        "FPS: " .. fps .. " | " ..
        "AVG: " .. avg .. " | " ..
        "1% low: " ..  low_1
end

function db_info.get_ram()
    return ("RAM: %.1f KB"):format(collectgarbage("count"))
end

return db_info
