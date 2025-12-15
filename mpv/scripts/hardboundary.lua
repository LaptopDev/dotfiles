-- This script prevents exit of playback after playback reaches EOF
-- Included is modular seeking logic for mpv, rightly separated from seek-anywhere.sh with its mpris handling, for establishing separation and
--   independence between mpv and other media players (such as the browser).
-- seeking independence *can* be handled in a unified way, by not using the registered event functions here 
--   and removing the defer-to-mpv case-logic in seek-anywhere.sh 
mp.msg.info("hardboundary: loaded")

-- shared EOF boundary
local boundary = nil

--CORRECTION LOGIC
local paused_at_boundary = false
------------------------------------------------------------
-- boundary setup
------------------------------------------------------------
mp.register_event("file-loaded", function()
    local duration = mp.get_property_number("duration")
    if not duration then
        mp.msg.error("hardboundary: no duration")
        return
    end
    boundary = duration - 0.05
    mp.msg.info(string.format("hardboundary: duration=%f boundary=%f", duration, boundary))
end)

------------------------------------------------------------
-- fixed-step seeking
------------------------------------------------------------
--CORRECTION LOGIC
mp.register_script_message("hardseek-relative", function(val)
    local delta = tonumber(val)
    if not delta then return end

    local cur = mp.get_property_number("time-pos")
    if not cur then return end

    local target = cur + delta

    -- boundary clamp
    if boundary and delta > 0 and target >= boundary then
        mp.set_property_number("time-pos", boundary)
        mp.set_property_bool("pause", true)
        paused_at_boundary = true
        return
    end

    -- normal movement
    mp.set_property_number("time-pos", target)

    -- only resume if we were paused by boundary and moved backward
    if paused_at_boundary and delta < 0 then
        mp.set_property_bool("pause", false)
        paused_at_boundary = false
    end
end)




------------------------------------------------------------
-- dynamic scroll wheel scrubbing (scrollseek)
------------------------------------------------------------

local last_time = 0
local velocity  = 0
local base_step = 1.0
local max_step  = 20.0
local decay     = 0.65

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end


--CORRECTION LOGIC
mp.register_script_message("scrollseek", function(dir)
    local now = mp.get_time()
    local dt = now - last_time
    last_time = now

    if dt < 0.08 then
        velocity = velocity + (0.08 - dt) * 40
    else
        velocity = velocity * decay
    end

    local step = base_step + velocity
    step = clamp(step, base_step, max_step)

    if dir == "down" then
        step = -step
    end

    local cur = mp.get_property_number("time-pos")
    if not cur then return end

    local target = cur + step

    -- boundary clamp
    if boundary and step > 0 and target >= boundary then
        mp.set_property_number("time-pos", boundary)
        mp.set_property_bool("pause", true)
        paused_at_boundary = true
        return
    end

    -- normal movement
    mp.set_property_number("time-pos", target)

    -- resume only when backing away from boundary pause
    if paused_at_boundary and step < 0 then
        mp.set_property_bool("pause", false)
        paused_at_boundary = false
    end
end)




