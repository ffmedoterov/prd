-- Добавляем функцию clamp в таблицу math
math.clamp = function(value, min, max)
    return value < min and min or (value > max and max or value)
end

local refs_aa = {
    fake_peek = { ui.reference("AA", "Other", "Fake peek") },
    on_shot_anti_aim = { ui.reference("AA", "Other", "On shot anti-aim") },
    leg_movement = ui.reference("AA", "Other", "Leg movement"),
    slow_motion = { ui.reference("AA", "Other", "Slow motion") },
}

local mode_enable_slider = ui.new_slider("AA", "Other", "[M] Mode Selector", 0, 1, 0)

local mode_label = ui.new_label("AA", "Other", "Current Mode: Classic Mode")

local prediction = ui.new_checkbox("AA", "Other", "[P] Predictive Boost")
local disableinterpolation = ui.new_checkbox("AA", "Other", "[T] Time Warp Disabler")
local interp_smooth_bind = ui.new_hotkey("AA", "Other", "[INTERP] Smooth Interp Change")

local function update_mode_label()
    local slider_value = ui.get(mode_enable_slider)
    if slider_value == 0 then
        ui.set(mode_label, "Current Mode: Classic Mode")
    else
        ui.set(mode_label, "Current Mode: Turbo Mode")
    end
end

local function update_ui_visibility()
    local slider_value = ui.get(mode_enable_slider)

    if slider_value == 0 then
        ui.set_visible(refs_aa.slow_motion[1], true)
        ui.set_visible(refs_aa.slow_motion[2], true)
        ui.set_visible(refs_aa.leg_movement, true)
        ui.set_visible(refs_aa.on_shot_anti_aim[1], true)
        ui.set_visible(refs_aa.on_shot_anti_aim[2], true)
        ui.set_visible(refs_aa.fake_peek[1], true)
        ui.set_visible(refs_aa.fake_peek[2], true)

        ui.set_visible(prediction, false)
        ui.set_visible(disableinterpolation, false)
        ui.set_visible(interp_smooth_bind, false)
    else
        ui.set_visible(refs_aa.slow_motion[1], false)
        ui.set_visible(refs_aa.slow_motion[2], false)
        ui.set_visible(refs_aa.leg_movement, false)
        ui.set_visible(refs_aa.on_shot_anti_aim[1], false)
        ui.set_visible(refs_aa.on_shot_anti_aim[2], false)
        ui.set_visible(refs_aa.fake_peek[1], false)
        ui.set_visible(refs_aa.fake_peek[2], false)

        ui.set_visible(prediction, true)
        ui.set_visible(disableinterpolation, ui.get(prediction))
        ui.set_visible(interp_smooth_bind, true)
    end
end

ui.set_callback(mode_enable_slider, function()
    update_mode_label()
    update_ui_visibility()
end)

ui.set_callback(prediction, update_ui_visibility)

update_mode_label()
update_ui_visibility()

ui.set_visible(disableinterpolation, false)

local start_interp_value = 0.015625
local end_interp_value = 0.029125

local interpolation_duration = 0.5

local is_interpolating = false
local interpolation_start_time = 0

local function smooth_interp()
    if not is_interpolating then return end

    local current_time = globals.realtime()

    local progress = (current_time - interpolation_start_time) / interpolation_duration
    progress = math.clamp(progress, 0, 1)

    local current_interp_value = start_interp_value + (end_interp_value - start_interp_value) * progress

    cvar.cl_interp:set_float(current_interp_value)

    if progress >= 1 then
        is_interpolating = false
    end
end

client.set_event_callback("paint", function()
    if ui.get(interp_smooth_bind) then
        if not is_interpolating then
            is_interpolating = true
            interpolation_start_time = globals.realtime()
        end
        smooth_interp()
    else
        is_interpolating = false
    end
end)

local function interpolate()
    if ui.get(disableinterpolation) then
        cvar.cl_interpolate:set_int(0)
    else
        cvar.cl_interpolate:set_int(1)
    end
end

local function impprediction()
    if ui.get(prediction) then
        cvar.cl_interp_ratio:set_int(0)
        cvar.cl_interp:set_int(0)
        cvar.cl_updaterate:set_int(62)
    else
        cvar.cl_interp_ratio:set_int(1)
        cvar.cl_interp:set_float(0.015625)
        cvar.cl_updaterate:set_int(64)
    end
end

client.set_event_callback("setup_command", function(cmd)
    interpolate()
    impprediction()
end)
