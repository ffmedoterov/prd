local ffi = require('ffi')
local pui = require('gamesense/pui')
local base64 = require('gamesense/base64')
local clipboard = require('gamesense/clipboard')
local c_entity = require ('gamesense/entity')
local http = require ('gamesense/http')
local vector = require "vector"
local steamworks = require('gamesense/steamworks')
local surface = require 'gamesense/surface'

local a = function (...) return ... end

local surface_create_font, surface_get_text_size, surface_draw_text = surface.create_font, surface.get_text_size, surface.draw_text
local verdana = surface_create_font('Verdana', 12, 400, {})

client.exec("Clear")
local b_2, b_1 = {}, {}

local A_1 = {
    A_2 = panorama.open("CSGOHud").MyPersonaAPI.GetName(),
    A_3 = "DEBUG", -- build
    A_4 = "Predict"-- Lua
}


local b_3 = {}

b_3.b_4 = function (t, r, k) local result = {} for i, v in ipairs(t) do n = k and v[k] or i result[n] = r == nil and i or v[r] end return result end
b_3.b_5 = function (t, j)  for i = 1, #t do if t[i] == j then return i end end  end
b_3.b_6 = function (t)  local res = {} for i = 1, table.maxn(t) do if t[i] ~= nil then res[#res+1] = t[i] end end return res  end



local gram_create = function(value, count) local gram = { }; for i=1, count do gram[i] = value; end return gram; end
local gram_update = function(tab, value, forced) local new_tab = tab; if forced or new_tab[#new_tab] ~= value then table.insert(new_tab, value); table.remove(new_tab, 1); end; tab = new_tab; end
local get_average = function(tab) local elements, sum = 0, 0; for k, v in pairs(tab) do sum = sum + v; elements = elements + 1; end return sum / elements; end

local function get_velocity(player)
    local x,y,z = entity.get_prop(player, "m_vecVelocity")
    if x == nil then return end
    return math.sqrt(x*x + y*y + z*z)
end

-- @region FFI start
local angle3d_struct = ffi.typeof("struct { float pitch; float yaw; float roll; }")
local vec_struct = ffi.typeof("struct { float x; float y; float z; }")

local cUserCmd =
    ffi.typeof(
    [[
    struct
    {
        uintptr_t vfptr;
        int command_number;
        int tick_count;
        $ viewangles;
        $ aimdirection;
        float forwardmove;
        float sidemove;
        float upmove;
        int buttons;
        uint8_t impulse;
        int weaponselect;
        int weaponsubtype;
        int random_seed;
        short mousedx;
        short mousedy;
        bool hasbeenpredicted;
        $ headangles;
        $ headoffset;
        bool send_packet; 
    }
    ]],
    angle3d_struct,
    vec_struct,
    angle3d_struct,
    vec_struct
)

local client_sig = client.find_signature("client.dll", "\xB9\xCC\xCC\xCC\xCC\x8B\x40\x38\xFF\xD0\x84\xC0\x0F\x85") or error("client.dll!:input not found.")
local get_cUserCmd = ffi.typeof("$* (__thiscall*)(uintptr_t ecx, int nSlot, int sequence_number)", cUserCmd)
local input_vtbl = ffi.typeof([[struct{uintptr_t padding[8];$ GetUserCmd;}]],get_cUserCmd)
local input = ffi.typeof([[struct{$* vfptr;}*]], input_vtbl)
local get_input = ffi.cast(input,ffi.cast("uintptr_t**",tonumber(ffi.cast("uintptr_t", client_sig)) + 1)[0])
--#endergion

local s_2 = {
    s_1 = {
        anti_aim = {ui.reference("AA", "Anti-aimbot angles", "Enabled")},
        pitch = {ui.reference("AA", "Anti-aimbot angles", "Pitch")},
        yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
        yawbase = ui.reference("AA", "Anti-aimbot angles", "Yaw Base"),
        yawjitter = { ui.reference("AA", "Anti-aimbot angles", "Yaw jitter") },
        bodyyaw = { ui.reference("AA", "Anti-aimbot angles", "Body yaw") },
        fs_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
        roll = ui.reference("AA", "Anti-aimbot angles", "Roll"),
        freeStand = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
        edgeyaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
        slow = { ui.reference("AA", "Other", "Slow motion") },
        onshotaa = {ui.reference("AA","Other", "On shot anti-aim")},
        fakelaglimit = {ui.reference("AA","Fake lag", "Limit")},
        fakelagvariance = {ui.reference("AA","Fake lag", "Variance")},
        fakelagamount = {ui.reference("AA","Fake lag", "Amount")},
        fakelagenabled = {ui.reference("AA","Fake lag", "Enabled")},
        legmovement = {ui.reference("AA","Other", "Leg movement")},
        fakepeek = {ui.reference("AA","Other", "Fake peek")},
    },
    s_0 = {
        qp = {ui.reference('RAGE', 'Other', 'Quick peek assist')},
        weapon_type = ui.reference('Rage', 'Weapon type', 'Weapon type'),
        rage_cb = { ui.reference("RAGE", "Aimbot", "Enabled") },
        fakeduck = ui.reference('RAGE', 'Other', 'Duck peek assist'),
        dt = { ui.reference('RAGE', 'Aimbot', 'Double tap') },
        scope = ui.reference('misc', 'miscellaneous', 'override zoom fov'),
        dmg = { ui.reference('RAGE', "Aimbot", 'Minimum damage override')},
        hit_chance = pui.reference("RAGE", "Aimbot", "Minimum hit chance"),
    }
}

--#region for Tabs // AA
--#region :: Traverse

local function traverse_table(tbl, prefix)
    prefix = prefix or ""
    local stack = {{tbl, prefix}}

    while #stack > 0 do
        local current = table.remove(stack)
        local current_tbl = current[1]
        local current_prefix = current[2]

        for key, value in pairs(current_tbl) do
            local full_key = current_prefix .. key
            if type(value) == "table" then
                table.insert(stack, {value, full_key .. "."})
            else
                ui.set_visible(value, false)
            end
        end
    end
end

local function traverse_table_on(tbl, prefix)
    prefix = prefix or ""
    local stack = {{tbl, prefix}}

    while #stack > 0 do
        local current = table.remove(stack)
        local current_tbl = current[1]
        local current_prefix = current[2]

        for key, value in pairs(current_tbl) do
            local full_key = current_prefix .. key
            if type(value) == "table" then
                table.insert(stack, {value, full_key .. "."})
            else
                ui.set_visible(value, true)
            end
        end
    end
end

--#endregion Traverse


-- client.set_event_callback("paint_ui", function()
--     traverse_table(s_2.s_1)
-- end)

client.set_event_callback("shutdown", function()
    traverse_table_on(s_2.s_1)
    cvar.cl_interp:set_float(0.015625)
    cvar.con_filter_enable:set_int(0)
    cvar.con_filter_text:set_string("")
    client.exec("con_filter_enable 0")
end)


--#region :: Menu elements

lerp = function(a,b,p) 
    return a + (b - a) * globals.frametime() * p
end

local breathe = function(offset, multiplier)
    local m_speed = globals.realtime() * (multiplier or 1.0);
    local m_factor = m_speed % math.pi;
  
    local m_sin = math.sin(m_factor + (offset or 0));
    local m_abs = math.abs(m_sin);
  
    return m_abs
end

calculateGradient = function(color1, color2, color3, color4, text, speed)
    local r1, g1, b1, a1 = color1[1], color1[2], color1[3], color1[4]
    local r2, g2, b2, a2 = color2[1], color2[2], color2[3], color2[4]
    local r3, g3, b3, a3 = color3[1], color3[2], color3[3], color3[4]
    local r4, g4, b4, a4 = color4[1], color4[2], color4[3], color4[4]
    
    local highlight_fraction = (globals.realtime() / 4 % 1.2 * speed) - 1.2
    local output = ''
    
    for idx = 1, #text do
        local character = text:sub(idx, idx)
        local character_fraction = idx / #text
        local r, g, b, a
        
        if character_fraction <= 0.33 then
            local fraction = character_fraction / 0.33
            r = r1 + (r2 - r1) * fraction
            g = g1 + (g2 - g1) * fraction
            b = b1 + (b2 - b1) * fraction
            a = a1 + (a2 - a1) * fraction
        elseif character_fraction <= 0.66 then
            local fraction = (character_fraction - 0.33) / 0.33
            r = r2 + (r3 - r2) * fraction
            g = g2 + (g3 - g2) * fraction
            b = b2 + (b3 - b2) * fraction
            a = a2 + (a3 - a2) * fraction
        else
            local fraction = (character_fraction - 0.66) / 0.34
            r = r3 + (r4 - r3) * fraction
            g = g3 + (g4 - g3) * fraction
            b = b3 + (b4 - b3) * fraction
            a = a3 + (a4 - a3) * fraction
        end
        
        local highlight_delta = (character_fraction - highlight_fraction)
        if highlight_delta >= 0 and highlight_delta <= 1.4 then
            if highlight_delta > 0.7 then
                highlight_delta = 1.4 - highlight_delta
            end
            local r_fraction, g_fraction, b_fraction, a_fraction = r4 - r, g4 - g, b4 - b, a4 - a
            r = r + r_fraction * highlight_delta / 0.8
            g = g + g_fraction * highlight_delta / 0.8
            b = b + b_fraction * highlight_delta / 0.8
            a = a + a_fraction * highlight_delta / 0.8
        end
        
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r, g, b, a, text:sub(idx, idx))
    end
    
    return output
end

local tabs = {
    angle = pui.group('aa', 'anti-aimbot angles'),
    fake = pui.group('aa', 'fake lag'),
    other = pui.group('aa', 'other')
}

b_2.rage = {
    lab = tabs.other:label("Rage"),
    space = tabs.other:label("\a373737FF??????????????????????????"),
    expdt = tabs.other:checkbox("\aFD002FFFdtfix"),
    airstop = tabs.other:checkbox("Air Stop", 0x00),
    predict = tabs.other:checkbox("\v?\r Penis \v?\r"),
    hotexp = tabs.other:hotkey("\v?\r Liberate \aFD002FFFme\r, of nigger"),
    pingpos = tabs.other:combobox("Ping Variations", {"High", "Low"}),
    selectgun = tabs.other:combobox("\n", {"-", "AWP", "SCOUT", "AUTO", "R8"}),
    slideawp = tabs.other:combobox("\n", {"Disabled", "Medium", "Maximum", "Extreme", "Custom"}),
    slidescout = tabs.other:combobox("\n",{"Disabled", "Medium", "Maximum", "Extreme", "Custom"}),
    slideauto = tabs.other:combobox("\n",{"Disabled", "Medium", "Maximum", "Extreme", "Custom"}),
    slider8 = tabs.other:combobox("\n",{"Disabled", "Medium", "Maximum", "Extreme", "Custom"}),
	custom_awp = tabs.other:textbox("Custom awp value"),
	custom_scout = tabs.other:textbox("Custom scout value"),
	custom_auto = tabs.other:textbox("Custom auto value"),
	custom_r8 = tabs.other:textbox("Custom r8 value"),
}

function desyncside()
    if not entity.get_local_player() or not entity.is_alive(entity.get_local_player()) then
        return
    end
    local bodyyaw = entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60
    local side = bodyyaw > 0 and -1 or 1
    return side
end

--#region :: Drag another
local vars = {}

local emberlash = {}

vars.drag = {}

local color do

    local helpers = {
		RGBtoHEX = a(function (col, short)
			return string.format(short and "%02X%02X%02X" or "%02X%02X%02X%02X", col.r, col.g, col.b, col.a)
		end),
		HEXtoRGB = a(function (hex)
			hex = string.gsub(hex, "^#", "")
			return tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16), tonumber(string.sub(hex, 7, 8), 16) or 255
		end)
	}

    local create

    local mt = {
		__eq = a(function (a, b)
			return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
		end),
		lerp = a(function (f, t, w)
			return create(f.r + (t.r - f.r) * w, f.g + (t.g - f.g) * w, f.b + (t.b - f.b) * w, f.a + (t.a - f.a) * w)
		end),
		to_hex = helpers.RGBtoHEX,
		alphen = a(function (self, a, r)
			return create(self.r, self.g, self.b, r and a * self.a or a)
		end),
	}	mt.__index = mt


    create = ffi.metatype(ffi.typeof("struct { uint8_t r; uint8_t g; uint8_t b; uint8_t a; }"), mt)


    color = setmetatable({
		rgb = a(function (r,g,b,a)
			r = math.min(r or 255, 255)
			return create(r, g and math.min(g, 255) or r, b and math.min(b, 255) or r, a and math.min(a, 255) or 255)
		end),
		hex = a(function (hex)
			local r,g,b,a = helpers.HEXtoRGB(hex)
			return create(r,g,b,a)
		end)
	},{
		__call = a(function (self, r, g, b, a)
			return type(r) == "string" and self.hex(r) or self.rgb(r, g, b, a)
		end),
	})
end

local colors = {
	hex		= "\a74A6A9FF",
	accent	= color.hex("74A6A9"),
	back	= color.rgb(23, 26, 28),
	dark	= color.rgb(5, 6, 8),
	white	= color.rgb(255),
	black	= color.rgb(0),
	null	= color.rgb(0, 0, 0, 0),
	text	= color.rgb(230),
	panel = {
		l1 = color.rgb(5, 6, 8, 180),
		g1 = color.rgb(5, 6, 8, 140),
		l2 = color.rgb(23, 26, 28, 96),
		g2 = color.rgb(23, 26, 28, 140),
	}
}

local DPI, _DPI = 1, {}
local sw, sh = client.screen_size()
local asw, ash = sw, sh
local sc = {x = sw * .5, y = sh * .5}
local asc = {x = asw * .5, y = ash * .5}

-- #region - Callbacks

local callbacks do
	local event_mt = {
		__call = function (self, bool, fn)
			local action = bool and client.set_event_callback or client.unset_event_callback
			action(self[1], fn)
		end,
		set = function (self, fn)
			client.set_event_callback(self[1], fn)
		end,
		unset = function (self, fn)
			client.unset_event_callback(self[1], fn)
		end,
		fire = function (self, ...)
			client.fire_event(self[1], ...)
		end,
	}	event_mt.__index = event_mt

	callbacks = setmetatable({}, {
		__index = function (self, key)
			self[key] = setmetatable({key}, event_mt)
			return self[key]
		end,
	})
end

-- #endregion

local my = {
    valid = false,
}


local render do
	local alpha = 1
	local astack = {}

	local measurements = setmetatable({}, { __mode = "kv" })

	-- #region - dpi

	local dpi_flag = ""
	local dpi_ref = ui.reference("MISC", "Settings", "DPI scale")

	_DPI.scalable = false
	_DPI.callback = function ()
		local old = DPI
		DPI = _DPI.scalable and tonumber(ui.get(dpi_ref):sub(1, -2)) * .01 or 1

		sw, sh = client.screen_size()
		sw, sh = sw / DPI, sh / DPI
		sc.x, sc.y = sw * .5, sh * .5
		dpi_flag = DPI ~= 1 and "d" or ""

		if old ~= DPI then
			callbacks["hysteria::render_dpi"]:fire(DPI)
			old = DPI
		end
	end

	_DPI.callback()
	ui.set_callback(dpi_ref, _DPI.callback)

	-- #endregion

	-- #region - blur

	local blurs = setmetatable({}, {__mode = "kv"})

	do
		local function check_screen ()
			if sw == 0 or sh == 0 then
				_DPI.callback()
				asw, ash = client.screen_size()
				sw, sh = render.screen_size()
			else
				callbacks.paint_ui:unset(check_screen)
			end
		end
		callbacks.paint_ui:set(check_screen)
	end

	callbacks.paint:set(function ()
		for i = 1, #blurs do
			local v = blurs[i]
			if v then renderer.blur(v[1], v[2], v[3], v[4]) end
		end
		table.clear(blurs)
	end)
	callbacks.paint_ui:set(function ()
		table.clear(blurs)
	end)

	-- #endregion

	local F, C, R = math.floor, math.ceil, math.round

	--
	render = setmetatable({
		cheap = false,

		push_alpha = a(function (v)
			local len = #astack
			astack[len+1] = v
			alpha = alpha * astack[len+1] * (astack[len] or 1)
			if len > 255 then error "alpha stack exceeded 255 objects, report to developers" end
		end),
		pop_alpha = a(function ()
			local len = #astack
			astack[len], len = nil, len-1
			alpha = len == 0 and 1 or astack[len] * (astack[len-1] or 1)
		end),
		get_alpha = a(function ()  return alpha  end),

		blur = a(function (x, y, w, h, a, s)
			if not render.cheap and my.valid and (a or 1) * alpha > .25 then
				blurs[#blurs+1] = {F(x * DPI), F(y * DPI), F(w * DPI), F(h * DPI)}
			end
		end),
		gradient = a(function (x, y, w, h, c1, c2, dir)
			renderer.gradient(F(x * DPI), F(y * DPI), F(w * DPI), F(h * DPI), c1.r, c1.g, c1.b, c1.a * alpha, c2.r, c2.g, c2.b, c2.a * alpha, dir or false)
		end),

		line = a(function (xa, ya, xb, yb, c)
			renderer.line(F(xa * DPI), F(ya * DPI), F(xb * DPI), F(yb * DPI), c.r, c.g, c.b, c.a * alpha)
		end),
		rectangle = a(function (x, y, w, h, c, n)
			x, y, w, h, n = F(x * DPI), F(y * DPI), F(w * DPI), F(h * DPI), n and F(n * DPI) or 0
			local r, g, b, a = c.r, c.g, c.b, c.a * alpha

			if n == 0 then
				renderer.rectangle(x, y, w, h, r, g, b, a)
			else
				renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
				renderer.rectangle(x + n, y, w - n - n, n, r, g, b, a)
				renderer.circle(x + w - n, y + n, r, g, b, a, n, 90, 0.25)
				renderer.rectangle(x, y + n, w, h - n - n, r, g, b, a)
				renderer.circle(x + n, y + h - n, r, g, b, a, n, 270, 0.25)
				renderer.rectangle(x + n, y + h - n, w - n - n, n, r, g, b, a)
				renderer.circle(x + w - n, y + h - n, r, g, b, a, n, 0, 0.25)
			end
		end),
		rect_outline = a(function (x, y, w, h, c, n, t)
			x, y, w, h, n, t = F(x * DPI), F(y * DPI), F(w * DPI), F(h * DPI), n and F(n * DPI) or 0, t and F(t * DPI) or 1
			local r, g, b, a = c.r, c.g, c.b, c.a * alpha

			if n == 0 then
				renderer.rectangle(x, y, w - t, t, r, g, b, a)
				renderer.rectangle(x, y + t, t, h - t, r, g, b, a)
				renderer.rectangle(x + w - t, y, t, h - t, r, g, b, a)
				renderer.rectangle(x + t, y + h - t, w - t, t, r, g, b, a)
			else
				renderer.circle_outline(x + n, y + n, r, g, b, a, n, 180, 0.25, t)
				renderer.rectangle(x + n, y, w - n - n, t, r, g, b, a)
				renderer.circle_outline(x + w - n, y + n, r, g, b, a, n, 270, 0.25, t)
				renderer.rectangle(x, y + n, t, h - n - n, r, g, b, a)
				renderer.circle_outline(x + n, y + h - n, r, g, b, a, n, 90, 0.25, t)
				renderer.rectangle(x + n, y + h - t, w - n - n, t, r, g, b, a)
				renderer.circle_outline(x + w - n, y + h - n, r, g, b, a, n, 0, 0.25, t)
				renderer.rectangle(x + w - t, y + n, t, h - n - n, r, g, b, a)
			end
		end),
		triangle = a(function (x1, y1, x2, y2, x3, y3, c)
			x1, y1, x2, y2, x3, y3 = x1 * DPI, y1 * DPI, x2 * DPI, y2 * DPI, x3 * DPI, y3 * DPI
			renderer.triangle(x1, y1, x2, y2, x3, y3, c.r, c.g, c.b, c.a * alpha)
		end),

		circle = a(function (x, y, c, radius, start, percentage)
			renderer.circle(x * DPI, y * DPI, c.r, c.g, c.b, c.a * alpha, radius * DPI, start or 0, percentage or 1)
		end),
		circle_outline = a(function (x, y, c, radius, start, percentage, thickness)
			renderer.circle(x * DPI, y * DPI, c.r, c.g, c.b, c.a * alpha, radius * DPI, start or 0, percentage or 1, thickness * DPI)
		end),

		screen_size = a(function (raw)
			local w, h = client.screen_size()
			if raw then return w, h else return w / DPI, h / DPI end
		end),

		load_rgba = a(function (c, w, h) return renderer.load_rgba(c, w, h) end),
		load_jpg = a(function (c, w, h) return renderer.load_jpg(c, w, h) end),
		load_png = a(function (c, w, h) return renderer.load_png(c, w, h) end),
		load_svg = a(function (c, w, h) return renderer.load_svg(c, w, h) end),
		texture = a(function (id, x, y, w, h, c, mode)
			if not id then return end
			renderer.texture(id, F(x * DPI), F(y * DPI), F(w * DPI), F(h * DPI), c.r, c.g, c.b, c.a * alpha, mode or "f")
		end),

		text = a(function (x, y, c, flags, width, ...)
			renderer.text(x * DPI, y * DPI, c.r, c.g, c.b, c.a * alpha, (flags or "") .. dpi_flag, width or 0, ...)
		end),
		measure_text = a(function (flags, text)
			if not text or text == "" then return 0, 0 end
			text = text:gsub("\a%x%x%x%x%x%x%x%x", "")

			flags = (flags or "")

			local key = string.format("<%s>%s", flags, text)
			if not measurements[key] or measurements[key][1] == 0 then
				measurements[key] = { renderer.measure_text(flags, text) }
			end
			return measurements[key][1], measurements[key][2]
			-- return renderer.measure_text(flags, text)
		end),
	}, {__index = renderer})
end


textures = {
	corner_h = render.load_svg('<svg width="4" height="5.87" viewBox="0 0 4 6"><path fill="#fff" d="M0 6V4c0-2 2-4 4-4v2C2 2 0 4 0 6Z"/></svg>', 8, 12),
	corner_v = render.load_svg('<svg width="5.87" height="4" viewBox="0 0 6 4"><path fill="#fff" d="M2 0H0c0 2 2 4 4 4h2C4 4 2 2 2 0Z"/></svg>', 12, 8),
    logo = render.load_png("\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x20\x00\x00\x00\x20\x08\x06\x00\x00\x00\x73\x7A\x7A\xF4\x00\x00\x00\x06\x62\x4B\x47\x44\x00\x00\x00\x00\x00\x00\xF9\x43\xBB\x7F\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0E\xC3\x00\x00\x0E\xC3\x01\xC7\x6F\xA8\x64\x00\x00\x00\x07\x74\x49\x4D\x45\x07\xE4\x07\x08\x0E\x27\x1E\x21\xA8\x70\xB7\x00\x00\x00\x1D\x69\x54\x58\x74\x43\x6F\x6D\x6D\x65\x6E\x74\x00\x00\x00\x00\x00\x43\x72\x65\x61\x74\x65\x64\x20\x77\x69\x74\x68\x20\x47\x49\x4D\x50\x57\x81\x0E\x17\x00\x00\x00\xDB\x49\x44\x41\x54\x58\x85\xC5\x97\xD1\x0D\x80\x20\x0C\x44\xBF\x9C\xDC\xA0\x4B\x3A\xB7\xE0\x9E\xE0\x4F\x0F\xF5\x30\x88\xC1\xCC\x8D\x30\x31\xC5\x4D\x06\x2B\x9D\xFB\xC2\x9D\x07\x09\x0C\x0C\x8E\x62\x6E\x47\x44\x29\x24\x60\x0B\x40\x06\x4B\xA4\x92\x04\x58\x70\x61\x52\x1B\x5F\xE1\x6A\x69\x09\x2A\x41\x30\x40\x3F\x28\x11\x10\xD3\xCC\x1B\x88\xA8\xD9\xE7\x24\x16\x8A\xA4\xC4\x5C\x80\xB8\xDC\xC1\x3A\x48\x86\x58\xF0\xD6\x92\x95\x95\xD1\x67\xB8\x5A\x4A\x02\xFC\x44\xC4\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82", 9, 9)
}

render.edge_v = function (x, y, length, col)
	col = col or colors.accent
	render.texture(textures.corner_v, x, y + 4, 6, -4, col, "f")
	render.rectangle(x, y + 4, 2, length - 8, col)
	render.texture(textures.corner_v, x, y + length - 4, 6, 4, col, "f")
end
render.edge_h = function (x, y, length, col)
	col = col or colors.accent
	render.texture(textures.corner_h, x, y, 4, 6, col, "f")
	render.rectangle(x + 4, y, length - 8, 2, col)
	render.texture(textures.corner_h, x + length, y, -4, 6, col, "f")
end

render.rounded_side_v = function (x, y, w, h, c, n)
	x, y, w, h, n = x * DPI, y * DPI, w * DPI, h * DPI, (n or 0) * DPI
	local r, g, b, a = c.r, c.g, c.b, c.a * render.get_alpha()

	renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
	renderer.rectangle(x + n, y, w - n, n, r, g, b, a)
	renderer.rectangle(x, y + n, w, h - n - n, r, g, b, a)
	renderer.circle(x + n, y + h - n, r, g, b, a, n, 270, 0.25)
	renderer.rectangle(x + n, y + h - n, w - n, n, r, g, b, a)
end

render.rounded_side_h = function (x, y, w, h, c, n)
	x, y, w, h, n = x * DPI, y * DPI, w * DPI, h * DPI, (n or 0) * DPI
	local r, g, b, a = c.r, c.g, c.b, c.a * render.get_alpha()

	renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
	renderer.rectangle(x + n, y, w - n - n, n, r, g, b, a)
	renderer.circle(x + w - n, y + n, r, g, b, a, n, 90, 0.25)
	renderer.rectangle(x, y + n, w, h - n, r, g, b, a)
end

--#region: anima
math.clamp = function (x, a, b) if a > x then return a elseif b < x then return b else return x end end


local mouse = { x = 0, y = 0 } do
	local unlock_cursor = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 66, "void(__thiscall*)(void*)")
	local lock_cursor = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 67, "void(__thiscall*)(void*)")

	mouse.lock = function (bool)
		if bool then lock_cursor() else unlock_cursor() end
	end

	mouse.in_bounds = function (x, y, w, h)
		return (mouse.x >= x and mouse.y >= y) and (mouse.x <= (x + w) and mouse.y <= (y + h))
	end

	mouse.pressed = function (key)
		return client.key_state(key or 1)
	end

	callbacks.pre_render:set(function ()
		mouse.x, mouse.y = ui.mouse_position()
		mouse.x, mouse.y = mouse.x / DPI, mouse.y / DPI
	end)
end

local anima do
	local mt, animators = {}, setmetatable({}, {__mode = "kv"})
	local frametime, g_speed = globals.absoluteframetime(), 1

	--


	anima = {
		pulse = 0,

		easings = {
			pow = {
				function (x, p) return 1 - ((1 - x) ^ (p or 3)) end,
				function (x, p) return x ^ (p or 3) end,
				function (x, p) return x < 0.5 and 4 * math.pow(x, p or 3) or 1 - math.pow(-2 * x + 2, p or 3) * 0.5 end,
			}
		},

		lerp = a(function (a, b, s, t)
			local c = a + (b - a) * frametime * (s or 8) * g_speed
			return math.abs(b - c) < (t or .005) and b or c
		end),

		condition = a(function (id, c, s, e)
			local ctx = id[1] and id or animators[id]
			if not ctx then animators[id] = { c and 1 or 0, c }; ctx = animators[id] end

			s = s or 4
			local cur_s = s
			if type(s) == "table" then cur_s = c and s[1] or s[2] end

			ctx[1] = math.clamp(ctx[1] + ( frametime * math.abs(cur_s) * g_speed * (c and 1 or -1) ), 0, 1)

			return (ctx[1] % 1 == 0 or cur_s < 0) and ctx[1] or
			anima.easings.pow[e and (c and e[1][1] or e[2][1]) or (c and 1 or 3)](ctx[1], e and (c and e[1][2] or e[2][2]) or 3)
		end)
	}

	--

	mt = {
		__call = anima.condition
	}

	--
	callbacks.paint_ui:set(function ()
		anima.pulse = math.abs(globals.realtime() * 1 % 2 - 1)
		frametime = globals.absoluteframetime()
	end)
end

--#endregion

local menu = {}

callbacks.paint_ui:set(function ()
	menu.x, menu.y = ui.menu_position()
	menu.w, menu.h = ui.menu_size()
end)

local drag do
	local current

	local in_bounds = a(function (x, y, xa, ya, xb, yb)
		return (x >= xa and y >= ya) and (x <= xb and y <= yb)
	end)

	--
	local progress = { menu = {0}, bg = {0}, }

	callbacks.paint_ui:set(function ()
		local p1 = anima.condition(progress.bg, current ~= nil, 2)
		if p1 == 0 then return end

		render.push_alpha(p1)
		-- render.blur(0, 0, sw, sh, p1)
		render.rectangle(0, 0, sw, sh, colors.panel.l1)
		-- render.text(fonts.regular, vector(screen.x - 24, screen.y - 40), colors.text, "r", "Hold Shift to drag elements vertically or horizontally.\nHold Ctrl to disable grid aligning.")
		render.pop_alpha()
	end)

	--
	local process = a(function (self)
		local ctx = self.__drag
		if ctx.locked or not pui.menu_open then return end

		local held = mouse.pressed()
		local hovered = mouse.in_bounds(self.x, self.y, self.w, self.h) and not mouse.in_bounds(menu.x, menu.y, menu.w, menu.h)

		--
		if held and ctx.ready == nil then
			ctx.ready = hovered
			ctx.ix, ctx.iy = self.x, self.y
			ctx.px, ctx.py = self.x - mouse.x, self.y - mouse.y
		end

		if held and ctx.ready then
			if current == nil and ctx.on_held then ctx.on_held(self, ctx) end
			current = (ctx.ready and current == nil) and self.id or current
			ctx.active = current == self.id
		elseif not held then
			if ctx.active and ctx.on_release then ctx.on_release(self, ctx) end
			ctx.active = false
			current, ctx.ready, ctx.aligning, ctx.px, ctx.py, ctx.ix, ctx.iy = nil, nil, nil, nil, nil, nil, nil
		end

		ctx.hovered = hovered or ctx.active

		--
		local prefer = { nil, nil }

		local dx, dy, dw, dh = self.x * DPI, self.y * DPI, self.w * DPI, self.h * DPI
		local wx, wy = ctx.px and (ctx.px + mouse.x) * DPI or dx, ctx.py and (ctx.py + mouse.y) * DPI or dy
		local cx, cy = dx + dw * .5, dy + dh * .5

		--

		local p1 = anima.condition(ctx.progress[1], ctx.hovered, 4)
		local p2 = anima.condition(ctx.progress[2], ctx.active, 4)

		render.rectangle(self.x - 3, self.y - 3, self.w + 6, self.h + 6, colors.white:alphen(12 + 24 * p1), 6)

		render.push_alpha(p2)

		if not client.key_state(0xA2) then
			local wcx, wcy = (wx + dw * .5) / DPI, (wy + dh * .5) / DPI
			for i, v in ipairs(ctx.rulers) do
				local spx, spy = v[2] / DPI, v[3] / DPI

				local dist = math.abs(v[1] and wcx - spx or wcy - spy)
				local allowed = dist < (10 * DPI)

				local pxy = v[1] and 1 or 2
				if not prefer[pxy] then
					prefer[pxy] = allowed and (v[1] and spx - self.w * .5 or spy - self.h * .5) or nil
				end

				v.p = v.p or {0}

				local adist = math.abs(v[1] and cx - spx or cy - spy)
				local pp = anima.condition(v.p, allowed or adist < (10 * DPI), -8) * .35 + 0.1
				render.rectangle(spx, spy, v[1] and 1 or v[4], v[1] and v[4] or 1, colors.white:alphen(pp, true))
			end
			if ctx.border[5] then
				local xa, ya, xb, yb = ctx.border[1], ctx.border[2], ctx.border[3], ctx.border[4]

				local inside = in_bounds(self.x, self.y, xa, ya, xb - self.w * .5 - 1, yb - self.h * .5 - 1)
				local p3 = anima.condition(ctx.progress[3], not inside)
				render.rect_outline(xa, ya, xb - xa, yb - ya, colors.white:alphen(p3 * .75 + .25, true), 4)
			end
		end

		render.pop_alpha()

		--
		if ctx.active then
			local fx, fy = prefer[1] or wx / DPI, prefer[2] or wy / DPI

			--
			local min_x, min_y = (ctx.border[1] - dw * .5) / DPI, (ctx.border[2] - dh * .5) / DPI
			local max_x, max_y = (ctx.border[3] - dw * .5) / DPI, (ctx.border[4] - dh * .5) / DPI

			local x, y = math.clamp(fx, math.max(min_x, 0), math.min(max_x, sw - self.w)), math.clamp(fy, math.max(min_y, 0), math.min(max_y, sh - self.h))
			self:set_position(x, y)

			if ctx.on_active then ctx.on_active(self, ctx, fin) end
		end
	end)


	--
	drag = {
		new = a(function (widget, props)
			vars.drag[widget.id] = {
				x = pui.slider("MISC", "Settings", widget.id ..":x", 0, 10000, (widget.x / sw) * 10000),
				y = pui.slider("MISC", "Settings", widget.id ..":y", 0, 10000, (widget.y / sh) * 10000),
			}

			vars.drag[widget.id].x:set_visible(false)
			vars.drag[widget.id].y:set_visible(false)
			vars.drag[widget.id].x:set_callback(function (this) widget.x = math.round(this.value * .0001 * sw) end, true)
			vars.drag[widget.id].y:set_callback(function (this) widget.y = math.round(this.value * .0001 * sh) end, true)

			--
			props = type(props) == "table" and props or {}

			widget.__drag = {
				locked = false, active = false, hovered = nil, aligning = nil,
				progress = {{0}, {0}, {0}},

				ix, iy = widget.x, widget.y,
				px, py = nil, nil,

				border = props.border or {0, 0, asw, ash},
				rulers = props.rulers or {},

				on_release = props.on_release, on_held = props.on_held, on_active = props.on_active,

				config = vars.drag[widget.id],
				work = process,
			}

			--
			callbacks["emberlash::render_dpi"]:set(function (new)
				vars.drag[widget.id].x:set(vars.drag[widget.id].x.value)
				vars.drag[widget.id].y:set(vars.drag[widget.id].y.value)
			end)

			callbacks.setup_command:set(function (cmd)
				if pui.menu_open and (widget.__drag.hovered or widget.__drag.active) then cmd.in_attack = 0 end
			end)
		end)
	}
end



local widget do
	local mt; mt = {
		update = function (self) return 1 end,
		paint = function (self, x, y, w, h) end,

		set_position = function (self, x, y)
			if self.__drag then
				if x then
					self.__drag.config.x:set( x / sw * 10000 )
					self.x = x
				end
				if y then
					self.__drag.config.y:set( y / sh * 10000 )
					self.y = y
				end
			else
				self.x, self.y = x or self.x, y or self.y
			end
		end,
		get_position = function (self)
			local ctx = self.__drag and self.__drag.config
			if not ctx then return self.x, self.y end

			return ctx.x.value * .0001 * sw, ctx.y.value * .0001 * sh
		end,

		__call = a(function (self)
			local __list, __drag = self.__list, self.__drag
			if __list then
				__list.items, __list.active = __list.collect(), 0
				for i = 1, #__list.items do
					if __list.items[i].active then __list.active = __list.active + 1 end
				end
			end
			self.alpha = self:update()

			render.push_alpha(self.alpha)

			if self.alpha > 0 then
				if __drag then __drag.work(self) end
				if __list then mt.traverse(self) end
				self:paint(self.x, self.y, self.w, self.h)
			end

			render.pop_alpha()
		end),

		enlist = function (self, collector, painter)
			self.__list = {
				items = {}, progress = setmetatable({}, { __mode = "k" }),
				longest = 0, active = 0, minwidth = self.w,
				collect = collector, paint = painter,
			}
		end,
		traverse = function (self)
			local ctx, offset = self.__list, 0
			local lx, ly = 0, 0
			ctx.active, ctx.longest = 0, 0

			for i = 1, #ctx.items do
				local v = ctx.items[i]
				local id = v.name or i
				ctx.progress[id] = ctx.progress[id] or {0}
				local p = anima.condition(ctx.progress[id], v.active)

				if p > 0 then
					render.push_alpha(p)
					lx, ly = ctx.paint(self, v, offset, p)
					render.pop_alpha()

					ctx.active, offset = ctx.active + 1, offset + (ly * p)
					ctx.longest = math.max(ctx.longest, lx)
				end
			end

			self.w = anima.lerp(self.w, math.max(ctx.longest, ctx.minwidth), 10, .5)
		end,

		lock = function (self, b)
			if not self.__drag then return end
			self.__drag.locked = b and true or false
		end,
	}	mt.__index = mt


	widget = {
		new = function (id, x, y, w, h, draggable)
			local self = {
				id = id, type = 0,
				x = x or 0, y = y or 0, w = w or 0, h = h or 0,
				alpha = 0, progress = {0}
			}

			if draggable then drag.new(self, draggable) end

			return setmetatable(self, mt)
		end,
	}
end

--#region :: Rage

local varsrage = {
    dt_charged = false,
}

local function rage(cmd)
    local lp = entity.get_local_player()
    if not lp then return end
    if b_2.rage.expdt:get() then
        local tickbase = entity.get_prop(lp, "m_nTickBase") - globals.tickcount()
        local doubletap_ref = ui.get(s_2.s_0.dt[1]) and ui.get(s_2.s_0.dt[2]) and not ui.get(s_2.s_0.fakeduck)
        local active_weapon = entity.get_prop(lp, "m_hActiveWeapon")
        if active_weapon == nil then return end
        local weapon_idx = entity.get_prop(active_weapon, "m_iItemDefinitionIndex")
        if weapon_idx == nil or weapon_idx == 64 then return end
        local LastShot = entity.get_prop(active_weapon, "m_fLastShotTime")
        if LastShot == nil then return end
        local single_fire_weapon = weapon_idx == 40 or weapon_idx == 9 or weapon_idx == 64 or weapon_idx == 27 or weapon_idx == 29 or weapon_idx == 35
        local value = single_fire_weapon and 1.50 or 0.50
        local in_attack = globals.curtime() - LastShot <= value

        if tickbase > 0 and doubletap_ref then
            if in_attack then
                ui.set(s_2.s_0.rage_cb[2], "Always on")
            else
                ui.set(s_2.s_0.rage_cb[2], "On hotkey")
            end
        else
            ui.set(s_2.s_0.rage_cb[2], "Always on")
        end
    end
end

local ticks = 0

local function airstop(cmd)
    local lp = entity.get_local_player()
    if not lp then return end
    
    if b_2.rage.airstop:get() then
        if b_2.rage.airstop.hotkey:get() then
            if cmd.quick_stop then
                if (globals.tickcount() - ticks) > 3 then
                    cmd.in_speed = 1
                end
            else
                ticks = globals.tickcount()
            end
        end
    end

end

client.set_event_callback("setup_command", function(cmd)
    if b_2.rage.airstop:get() then
        airstop(cmd)
    end

    -- if b_2.settings.selectfix:get("Leg Fucker") then
    --     ui.set(s_2.s_1.legmovement[1], cmd.command_number % 3 == 0 and "Off" or "Always slide")
    -- else
    --     ui.set(s_2.s_1.legmovement[1], "Off")
    -- end
end)

--#region :: GREMOARE

predict = function()
    local lp = entity.get_local_player()
    if not lp then return end
    local gun = entity.get_player_weapon(lp)
    local skeetweapon = ui.get(s_2.s_0.weapon_type)
    local weapon = b_2.rage.selectgun:get()
    local classname = entity.get_classname(gun)
    -- if not b_2.rage.predict:get() then return end
    if gun == nil then
        return
    end
    if b_2.rage.predict:get() and b_2.rage.hotexp:get() then
        if b_2.rage.pingpos:get() == "Low" then
            cvar.cl_interpolate:set_int(0)
            cvar.cl_interp_ratio:set_int(0)
            -- print(classname)

            if classname == "CWeaponSSG08" then
                if b_2.rage.slidescout:get() == "Disabled"  then
                    cvar.cl_interp:set_float(0.015625)
                end
                if b_2.rage.slidescout:get() == "Medium"  then
                    cvar.cl_interp:set_float(0.028000)
                end
                if b_2.rage.slidescout:get() == "Maximum"  then
                    cvar.cl_interp:set_float(0.029125)
                end
                if b_2.rage.slidescout:get() == "Extreme" then
                    cvar.cl_interp:set_float(0.031000)
				elseif b_2.rage.slidescout:get() == "Custom"  then
                    cvar.cl_interp:set_float(b_2.rage.custom_scout:get())
                end
            end

            if classname == "CWeaponAWP" then
                if b_2.rage.slideawp:get() == "Disabled" then
                    cvar.cl_interp:set_float(0.015625)
                elseif b_2.rage.slideawp:get() == "Medium" then
                    cvar.cl_interp:set_float(0.028000)
                elseif b_2.rage.slideawp:get() == "Maximum"  then
                    cvar.cl_interp:set_float(0.029125)
                elseif b_2.rage.slideawp:get() == "Extreme"  then
                    cvar.cl_interp:set_float(0.031000)
				elseif b_2.rage.slideawp:get() == "Custom"  then
                    cvar.cl_interp:set_float(b_2.rage.custom_awp:get())
                end
            end

            if classname == "CWeaponSCAR20" or  classname == "CWeaponG3SG1" then
                if b_2.rage.slideauto:get() == "Disabled" then
                    cvar.cl_interp:set_float(0.015625)
                elseif b_2.rage.slideauto:get() == "Medium" then
                    cvar.cl_interp:set_float(0.028000)
                elseif b_2.rage.slideauto:get() == "Maximum"  then
                    cvar.cl_interp:set_float(0.029125)
                elseif b_2.rage.slideauto:get() == "Extreme"  then
                    cvar.cl_interp:set_float(0.031000)
				elseif b_2.rage.slideauto:get() == "Custom"  then
                    cvar.cl_interp:set_float(b_2.rage.custom_auto:get())
                end
            end

            if classname == "CDEagle" then
                if b_2.rage.slider8:get() == "Disabled" then
                    cvar.cl_interp:set_float(0.015625)
                elseif b_2.rage.slider8:get() == "Medium" then
                    cvar.cl_interp:set_float(0.028000)
                elseif b_2.rage.slider8:get() == "Maximum" then
                    cvar.cl_interp:set_float(0.029125)
                elseif b_2.rage.slider8:get() == "Extreme" then
                    cvar.cl_interp:set_float(0.031000)
				elseif b_2.rage.slider8:get() == "Custom"  then
                    cvar.cl_interp:set_float(b_2.rage.custom_r8:get())
                end
            end
        elseif b_2.rage.pingpos:get() == "High" then
            cvar.cl_interp:set_float(0.020000)
            cvar.cl_interp_ratio:set_int(0)
            cvar.cl_interpolate:set_int(0)
        end
    else
        cvar.cl_interp:set_float(0.015625)
        cvar.cl_interp_ratio:set_int(2)
        cvar.cl_interpolate:set_int(1)
    end
end
--#endregion

 local function indicators()
    local lp = entity.get_local_player()
    if not lp then return end
    local screen = vector(client.screen_size())
    local position = screen*0.5
    local scope = entity.get_prop(lp, "m_bIsScoped")
    local space = 20
    local r, g, b, a = b_2.settings.center:get_color()

    local exploit = {
        is_dt = ui.get(s_2.s_0.dt[1]) and ui.get(s_2.s_0.dt[2]),
        is_os = ui.get(s_2.s_1.onshotaa[1]) and ui.get(s_2.s_1.onshotaa[2]),
    }

    col1 = { r, g, b, a }
    col2 = { 255, 255, 255, a }

    local leftdir = desyncside() == -1 and col1 or col2
    local rightdir = desyncside() == 1 and col1 or col2

    if scope ~= 0 then
        scoped = lerp(scoped, 40, 10)
    else
        scoped = lerp(scoped, 0, 10)
    end

    if ui.get(s_2.s_0.dmg[2]) then
        a1 = lerp(a1, 255, 10)
    else
        a1 = lerp(a1,0, 10)
    end

    if ui.get(s_2.s_0.qp[2]) then
        a2 = lerp(a2, 255, 10)
    else
        a2 = lerp(a2, 0, 10)
    end

    if ui.get(s_2.s_0.dt[2]) and doubletap_charged() then
        dist = lerp(dist, 7, 10)
    else
        dist = lerp(dist, 0, 10)
    end
     
    local time = globals.realtime() * -2

    local state = "unknown"
    if id == 1 then
        state = "Global"
    elseif id == 2 then
        state = "stand"
    elseif id == 3 then
        state = "walk"
    elseif id == 4 then
        state = "run"
    elseif id == 5 then
        state = "air"
    elseif id == 6 then
        state = "airc"
    elseif id == 7 then
        state = "duck"
    elseif id == 8 then
        state = "duckm"
    elseif id == 9 then
        state = "Fakelag"
    end


    if b_2.settings.center:get() and b_2.settings.indicators:get() then
        renderer.text(position.x + scoped, position.y + space, r,g,b,a, "cb", 0, "emberlash")
        renderer.rectangle(position.x + scoped , position.y + space + 7, 30, 2, leftdir[1], leftdir[2], leftdir[3], leftdir[4])
        renderer.rectangle(position.x + scoped - 30, position.y + space + 7, 30, 2, rightdir[1], rightdir[2], rightdir[3], rightdir[4])
        renderer.gradient(position.x + scoped - 29, position.y + space + 7, 60, 13, 0, 0, 0, 30, 0, 0, 0, 30, false)
        space = space + 15

        renderer.text(position.x + scoped, position.y + space, 255, 255, 255, 255, "-c", 0, "/".. string.upper(state) .. "/")
        space = space + 8

        if doubletap_charged() then
            circle = lerp(circle, 1.0, 10)
        else
            circle = lerp(circle, 0.0, 10)
        end

        if ui.get(s_2.s_0.dt[2]) then
            renderer.circle_outline(position.x + scoped + 10, position.y + space, r, g, b, a,  3, 90 , circle, 1)
            if doubletap_charged() then
                renderer.text(position.x + scoped, position.y +space, 255, 255, 255, 255, "-c", 0, "DT")
            else
                renderer.text(position.x + scoped, position.y + space, 255, 75, 75, 255, "-c", 0, "DT")
            end
        else
            renderer.text(position.x + scoped, position.y + space, 200, 200, 200, 200, "-c", 0, "DT")
        end

        space = space + 8

        renderer.text(position.x + scoped -13, position.y + space, r, g, b, a1, "-c", 0, 'MD')

        renderer.text(position.x + scoped + 13, position.y + space, r, g,b, a2, "-c", 0, "QP")

        if b_2.aa.advanced.hideshots.hotkey:get() then
            renderer.text(position.x + scoped, position.y + space, r, g, b, 255, "-c", 0, "OS")
        else
            renderer.text(position.x + scoped, position.y + space, 200, 200, 200, 200, "-c", 0, "OS")
        end
    end
end



local dependencies = {
    {menu = b_2.rage.hotexp, depend = {{b_2.rage.predict, true}}},
    {menu = b_2.rage.pingpos, depend = {{b_2.rage.predict, true}}},
    {menu = b_2.rage.selectgun, depend = {{b_2.rage.predict, true}, {b_2.rage.pingpos, "Low"}}},
    {menu = b_2.rage.slideauto, depend = {{b_2.rage.selectgun, "AUTO"}, {b_2.rage.predict, true}, {b_2.rage.pingpos, "Low"}}},
    {menu = b_2.rage.slidescout, depend = {{b_2.rage.selectgun, "SCOUT"}, {b_2.rage.predict, true}, {b_2.rage.pingpos, "Low"}}},
    {menu = b_2.rage.slider8, depend = {{b_2.rage.selectgun, "R8"}, {b_2.rage.predict, true}, {b_2.rage.pingpos, "Low"}}},
    {menu = b_2.rage.slideawp, depend = {{b_2.rage.selectgun, "AWP"}, {b_2.rage.predict, true},{b_2.rage.pingpos, "Low"}}},
	{menu = b_2.rage.custom_awp, depend = {{b_2.rage.selectgun, "AWP"}, {b_2.rage.predict, true},{b_2.rage.pingpos, "Low"},{b_2.rage.slideawp, "Custom"}}},
	{menu = b_2.rage.custom_scout, depend = {{b_2.rage.selectgun, "SCOUT"}, {b_2.rage.predict, true},{b_2.rage.pingpos, "Low"},{b_2.rage.slidescout, "Custom"}}},
	{menu = b_2.rage.custom_auto, depend = {{b_2.rage.selectgun, "AUTO"}, {b_2.rage.predict, true},{b_2.rage.pingpos, "Low"},{b_2.rage.slideauto, "Custom"}}},
	{menu = b_2.rage.custom_r8, depend = {{b_2.rage.selectgun, "R8"}, {b_2.rage.predict, true},{b_2.rage.pingpos, "Low"},{b_2.rage.slider8, "Custom"}}},
}

for _, dep in ipairs(dependencies) do
    pui.traverse(dep.menu, function(ref, path)
        ref:depend(unpack(dep.depend))
    end)
end

client.set_event_callback("setup_command", function(cmd)
    rage(cmd)
    predict()
end)



client.set_event_callback("paint", function()
    if not entity.is_alive(entity.get_local_player()) then return end
    local lp = entity.get_local_player()
    local scope = entity.get_prop(lp, "m_bIsScoped")
    -- indicators()
    
    if b_2.rage.airstop:get() and b_2.rage.airstop.hotkey:get() then
        renderer.indicator(215,211,213,255, "AIR-QS")
    end
    
    if b_2.rage.predict:get() and b_2.rage.hotexp:get() then
        render.indicator(215,211,213,255, "AHAH")
    end
end)