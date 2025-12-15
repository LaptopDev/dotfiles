-- Speed control with stable pitch mode
-- Manual toggle switches pitch mode
-- Speed changes respect current mode
-- Integer-step, reversible
-- Keys: [ ] speed, \ toggle mode, BS reset

local STEP       = 0.10
local MIN_STEP   = -9    -- 0.1x
local MAX_STEP   =  90   -- 10.0x

local step = 0
local preserve_pitch = false  -- false = chipmunk, true = pitch preserved

local function clamp_step()
    if step < MIN_STEP then step = MIN_STEP end
    if step > MAX_STEP then step = MAX_STEP end
end

local function apply_audio_chain()
    if preserve_pitch then
        mp.set_property_bool("audio-pitch-correction", true)
        --mp.set_property_bool("audio-pitch-correction", false)
        mp.commandv("af", "add", "@rb:rubberband")
    else
        mp.set_property_bool("audio-pitch-correction", false)
        mp.commandv("af", "remove", "@rb")
    end
end

local function apply_speed()
    local speed = 1.0 + step * STEP
    apply_audio_chain()
    mp.set_property_number("speed", speed)
    mp.osd_message(string.format(
        "Speed: %.2fx (%s)",
        speed,
        preserve_pitch and "pitch preserved" or "pitch follows"
    ))
end

-- ---------- META TOGGLE ----------

local function toggle_pitch_mode()
    preserve_pitch = not preserve_pitch
    apply_speed()  -- reapply at current step
end

-- ---------- CONTROLS ----------

local function faster()
    step = step + 1
    clamp_step()
    apply_speed()
end

local function slower()
    step = step - 1
    clamp_step()
    apply_speed()
end

local function reset()
    step = 0
    apply_speed()
end

-- ---------- INIT ----------

mp.register_event("file-loaded", function()
    step = 0
    apply_speed()
end)

-- ---------- KEYS ----------

mp.add_key_binding("[", "speed-slower", slower)
mp.add_key_binding("]", "speed-faster", faster)
mp.add_key_binding("\\", "pitch-toggle", toggle_pitch_mode)
mp.add_key_binding("BS", "speed-reset", reset)

-- ---------- IPC ----------

mp.register_script_message("speed-faster", faster)
mp.register_script_message("speed-slower", slower)
mp.register_script_message("pitch-toggle", toggle_pitch_mode)
mp.register_script_message("speed-reset",  reset)
