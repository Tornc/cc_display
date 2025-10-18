local db_info = {}

local MAX_FT_SAMPLES = 100

local frame_times = {}

local function round(n) return math.floor(n + 0.5) end

function db_info.get_frame_time(dt)
    table.insert(frame_times, dt)
    if #frame_times > MAX_FT_SAMPLES then table.remove(frame_times, 1) end

    local total = 0
    for i = 1, #frame_times do total = total + frame_times[i] end
    local avg = round(total / #frame_times)

    local sorted = {}
    for i, v in ipairs(frame_times) do sorted[i] = v end
    table.sort(sorted)
    local top_99 = sorted[math.min(#sorted, math.ceil(#sorted * 0.99))]

    return
        "Frame Time: " .. dt .. "ms | " ..
        "AVG: " .. avg .. "ms | " ..
        "99%: " .. top_99 .. "ms"
end

function db_info.get_mem()
    return ("MEM: %.1f KB"):format(collectgarbage("count"))
end

return db_info
