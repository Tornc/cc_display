local physics = {}

local GRAVITY = 0.05
local DRAG_COEFFICIENT = 0.9

local function particle(x, y, radius, density)
    --- @class Particle
    local self = {}
    self.x = x
    self.y = y
    self.r = radius
    self.m = density * (self.r * 2) * (self.r * 2)

    self.vx = (math.random() - 0.5) * 2
    self.vy = (math.random() - 0.5) * 2
    return self
end

local function move(p)
    p.vx = p.vx * DRAG_COEFFICIENT
    p.vy = p.vy * DRAG_COEFFICIENT
    p.vy = p.vy + GRAVITY
    p.x = p.x + p.vx
    p.y = p.y + p.vy
end

local function border_collision(p, w, h)
    if p.x - p.r <= 1 then
        p.vx = -p.vx
        p.x = 1 + p.r
    elseif p.x + p.r >= w then
        p.vx = -p.vx
        p.x = w - p.r
    end
    if p.y - p.r <= 1 then
        p.vy = -p.vy
        p.y  = 1 + p.r
    elseif p.y + p.r >= h then
        p.vy = -p.vy
        p.y = h - p.r
    end
end

local function mouse_collision(p, mx, my)
    if not (mx and my) then return end

    local r = 5     -- Mouse collision radius
    local force = 5 -- Mouse force

    local dx = p.x - mx
    local dy = p.y - my
    local dist_sq = dx * dx + dy * dy
    local rad_sq = r * r
    if dist_sq < rad_sq and dist_sq > 0 then
        local dist = math.sqrt(dist_sq)

        local dir_x = dx / dist
        local dir_y = dy / dist

        p.vx = p.vx + dir_x * force
        p.vy = p.vy + dir_y * force
    end
end

--- https://www.vobarian.com/collisions/2dcollisions2.pdf
local function particle_collision(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local r_sum = p1.r + p2.r
    local sq_dist = dx * dx + dy * dy

    if sq_dist > r_sum * r_sum or sq_dist <= 0 then return end
    if p1.m == 0 and p2.m == 0 then return end

    --- Unit vector
    local magnitude = math.sqrt(sq_dist)
    local v_un_x = dx / magnitude
    local v_un_y = dy / magnitude

    -- Unit tangent vector
    local v_ut_x = -v_un_y
    local v_ut_y = v_un_x

    -- Project velocity vectors onto unit normal and unit tangent vectors (dot product)
    local v1n = v_un_x * p1.vx + v_un_y * p1.vy
    local v1t = v_ut_x * p1.vx + v_ut_y * p1.vy
    local v2n = v_un_x * p2.vx + v_un_y * p2.vy
    local v2t = v_ut_x * p2.vx + v_ut_y * p2.vy

    -- Calculate new tangential velocities (no change)
    local v1t_hat = v1t
    local v2t_hat = v2t

    -- Calulate new normal velocities with 1D collision formula
    local v1n_hat = (v1n * (p1.m - p2.m) + 2 * p2.m * v2n) / (p1.m + p2.m)
    local v2n_hat = (v2n * (p2.m - p1.m) + 2 * p1.m * v1n) / (p1.m + p2.m)

    -- Calulate new normal and tangential velocity vectors
    local v_v1n_hat_x = v1n_hat * v_un_x
    local v_v1n_hat_y = v1n_hat * v_un_y
    local v_v1t_hat_x = v1t_hat * v_ut_x
    local v_v1t_hat_y = v1t_hat * v_ut_y
    local v_v2n_hat_x = v2n_hat * v_un_x
    local v_v2n_hat_y = v2n_hat * v_un_y
    local v_v2t_hat_x = v2t_hat * v_ut_x
    local v_v2t_hat_y = v2t_hat * v_ut_y

    -- Calculate final velocity vectors
    p1.vx = v_v1n_hat_x + v_v1t_hat_x
    p1.vy = v_v1n_hat_y + v_v1t_hat_y
    p2.vx = v_v2n_hat_x + v_v2t_hat_x
    p2.vy = v_v2n_hat_y + v_v2t_hat_y
end

--- @param v_tbl table<any>
--- @param p_tbl table<number> Must have same length. Must sum to 1.
--- @return any
local function weighted_random_pick(v_tbl, p_tbl)
    local rand_val = math.random()
    local cum_weight = 0
    for i, weight in ipairs(p_tbl) do
        cum_weight = cum_weight + weight
        if rand_val <= cum_weight then return v_tbl[i] end
    end
    return v_tbl[#v_tbl] -- Fallback
end

function physics.particle_manager()
    local self = {}

    function self.create(n, w, h)
        self.w = w
        self.h = h
        self.particles = {}
        local radii = { 0.5, 1.5, 2.5, 3.5 }
        local probs = { 0.65, 0.25, 0.08, 0.02 }
        for _ = 1, n do
            table.insert(
                self.particles,
                particle(
                    math.random(1, self.w),
                    math.random(1, self.h),
                    weighted_random_pick(radii, probs),
                    math.random(1, 20)
                )
            )
        end
        return self
    end

    function self.update(mx, my)
        for i = 1, #self.particles do
            local p = self.particles[i]
            move(p)
            mouse_collision(p, mx, my)
            --- @TODO: spatial partitioning
            for j = i + 1, #self.particles do
                particle_collision(p, self.particles[j])
            end
            border_collision(p, self.w, self.h)
        end
    end

    return self
end

return physics
