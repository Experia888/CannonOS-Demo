--[[
 - Automatic Coordinate Targeting System Demo Project
 - Authors: Experia888 (GitHub: https://github.com/Experia888), Priton (GitHub: https://github.com/Priton-CE)
 - GitHub: https://github.com/Experia888/CannonOS-Demo
 - Purpose: Enable Warcrimes
]]--

require "math"

function determine_pitch(velocity, distance, height, barrel_len, algorithm_accuracy)
    local angle = -30.0
    local ticks = 0

    for i = 1.0,0.0,-algorithm_accuracy do
        if i < algorithm_accuracy then break end --make sure to abort if we have no success
        for a = angle,60.0,i do
            -- simulate and save the trajectory and ticks
            local sim_d, t = simulate_projectile(velocity, a, height, barrel_len)

            -- check for errors
            if not (sim_d == nil) then
                -- evaluate
                if sim_d < distance then
                    -- undershot
                    angle = a
                    ticks = t
                elseif sim_d == distance then
                    -- perfect match
                    return a, t
                else
                    --overshot
                    break
                end
            end
        end
    end
    return angle, ticks
end

function simulate_projectile(velocity, angle, height, barrel_len)
    -- minecraft constants for type: projectile
    local gravity = 20
    local drag = 0.99 -- = 1 - 0.01

    -- coordinates of the projectile
    local x = 0 + math.cos(math.rad(angle)) * barrel_len
    local y = height + math.sin(math.rad(angle)) * barrel_len

    -- start velocity
    local vx = math.cos(math.rad(angle)) * velocity
    local vy = math.sin(math.rad(angle)) * velocity

    -- output variables
    local ticks = 0

    local is_above_target = false
    for i = 0,1000,1 do
        if not is_above_target then
            if y >= 0 then
                -- update the status if we are above the target
                is_above_target = true
            elseif vy < 0 then
                -- we are below the target
                -- make sure we are rising, else abort since we will never finish
                return nil, i
            end
        end

        -- update position
        x = x + vx / 20
        y = y + vy / 20

        -- update velocity with gravity
        vy = vy - gravity / 20

        -- update velocity with drag
        vx = vx * drag
        vy = vy * drag

        -- check if the altitude of the target is hit
        if y <= 0 and is_above_target then
            ticks = i
            break
        end
    end
    return x, ticks
end

-- require exports
return {simulate_projectile=simulate_projectile, determine_pitch=determine_pitch}
