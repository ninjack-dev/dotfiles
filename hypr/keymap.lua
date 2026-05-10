---@diagnostic disable: lowercase-global
local bind = hl.bind

---@type function(string?)
main_mod = function(keys)
	return "SUPER" .. (keys and (" + " .. keys) or "")
end

local e14_F_keys = {
	F4 = "XF86AudioMicMute",
	F7 = "XF86Display",
	F8 = "XF86WLAN",
	F10 = "XF86SelectiveScreenshot",
	F11 = "XKB_KEY_oslash",
	F12 = "XF86Favorites",
}

bind(
	main_mod(),
	hl.dsp.global(":Super"),
	{ description = "Global SUPER detection shortcut, used to provide held key context to some widgets" }
)

bind(main_mod("W"), hl.dsp.window.close(), { description = "Close the active window" })
bind(main_mod("CTRL + Shift_L + Alt_L  + B"), hl.dsp.force_renderer_reload(), { description = "Reload Hyprland" })
-- TODO: Replace with hyprshutdown:
-- hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
bind(main_mod("Delete"), hl.dsp.exit(), { description = "Exit Hyprland" })
bind(main_mod("V"), hl.dsp.window.float(), { description = "Toggle the floating state of the active window" })
bind(
	main_mod("R"),
	hl.dsp.exec_cmd(string.format('pkill -f "%s" || %s', workspace_renamer, workspace_renamer)),
	{ description = "Rename the active workspace" }
)

bind(main_mod("H"), hl.dsp.focus({ direction = "left" }), { description = "Focus window left of active" })
bind(main_mod("J"), hl.dsp.focus({ direction = "down" }), { description = "Focus window below active" })
bind(main_mod("K"), hl.dsp.focus({ direction = "up" }), { description = "Focus window above active" })
bind(main_mod("L"), hl.dsp.focus({ direction = "right" }), { description = "Focus window right of active" })

bind(main_mod("SHIFT + H"), hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
bind(main_mod("SHIFT + J"), hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
bind(main_mod("SHIFT + K"), hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
bind(main_mod("SHIFT + L"), hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })

bind(main_mod("P"), hl.dsp.window.pin({ window = "floating" }), { description = "Pin the active floating window" })

bind(
	main_mod("Z"),
	hl.dsp.exec_cmd(
		"ags quit -i bar; ags run ~/.config/ags/bar; ags quit -i notifications; ags run ~/.config/ags/notifications"
	),
	{ description = "Restart AGS widgets" }
)

bind(main_mod("Tab"), hl.dsp.window.cycle_next(), { description = "Cycle to next window in workspace" })

bind(
	main_mod("F"),
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "Maximize a window" }
)
bind(
	main_mod("SHIFT + F"),
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Fullscreen a window" }
)

for i = 1, 10 do
	local key = i % 10
	bind(main_mod(key), hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
	bind(
		main_mod("ALT + " .. key),
		hl.dsp.focus({ workspace = i + 10 }),
		{ description = "Go to workspace " .. i + 10 }
	)
	bind(
		main_mod("SHIFT + " .. key),
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move active window to workspace " .. i }
	)
	bind(
		main_mod("ALT + SHIFT + " .. key),
		hl.dsp.window.move({ workspace = i + 10 }),
		{ description = "Move active window to workspace " .. i + 10 }
	)
end

bind(main_mod("mouse:272"), hl.dsp.window.drag(), { description = "Move the window by dragging", mouse = true })
bind(main_mod("mouse:273"), hl.dsp.window.resize(), { description = "Resize the window by dragging", mouse = true })

local volume_delta = 5
bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(string.format("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ %d%%+", volume_delta)),
	{ description = string.format("Raise volume by %s%%", volume_delta), locked = true, repeating = true }
)
bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(string.format("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ %d%%+", volume_delta)),
	{ description = string.format("Lower volume by %s%%", volume_delta), locked = true, repeating = true }
)
bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ description = "Toggle audio mute", locked = true, repeating = true }
)
bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ description = "Toggle microphone mute", locked = true, repeating = true }
)

local brightness_delta = 10
bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(string.format("brightnessctl -e4 -n2 set %d%%+", brightness_delta)),
	{ description = string.format("Raise brightness by %d%%", brightness_delta), locked = true, repeating = true }
)
bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(string.format("brightnessctl -e4 -n2 set %d%%-", brightness_delta)),
	{ description = string.format("Lower brightness by %d%%", brightness_delta), locked = true, repeating = true }
)

bind(
	"Print",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"),
	{ description = "Take a selection-based screenshot" }
)
bind(
	main_mod("Print"),
	hl.dsp.exec_cmd('grim - | tee "$HOME"/Pictures/Captures/"$(date +%m-%y)"/"$(date +%d-%H:%M)".png | wl-copy'),
	{ description = "Take a selection-based screenshot" }
)
-- TODO: Fix wf-recorder, or use an alternative
bind(
	"SHIFT + Print",
	hl.dsp.exec_cmd(
		'pkill wf-recorder || wf-recorder --geometry "$(slurp -d)" -F fps=20 -c gif -f "$HOME/Pictures/Captures/$(date +%m-%y)/$(date +%d-%H:%M).gif"'
	),
	{ description = "Begin screen recording, or kill current screen recorder process" }
)

-- Program launch binds
---@param program  string|function|HL.Dispatcher
local launch = function(key, program, description)
	if type(program) == "string" then
		program = hl.dsp.exec_cmd(program)
	end
	bind(key, program, { description = description })
end

launch(main_mod("Q"), terminal, "Open default terminal (kitty)")
launch(main_mod("SHIFT + Q"), terminal .. " shell-picker.sh", "Open default terminal (kitty) with shell-picker TUI")

launch(main_mod("B"), browser, "Launch new Brave browser window")
launch(main_mod("SHIFT + B"), browser_private, "Launch new private browser window")

launch(main_mod("CTRL + H"), browser .. ' --app="https://wiki.hypr.land"', "Open Hyprland wiki in Brave")

launch(main_mod("E"), file_manager, "Open file manager (Dolphin)")

launch(main_mod("Space"), string.format('pkill -f "%s" || %s', menu, menu), "Toggle system launcher (Rofi)")

launch(main_mod("C"), "rofi -show configuration", "Open menu for editing dotfiles")

launch(main_mod("C"), "hyprpicker --autocopy --format=hex", "Open color picker")

launch(main_mod("F1"), calculator, "Launch calculator (Qalculate)")
launch(main_mod("F2"), "launch-named-app Excalidraw", "Launch whiteboard (Excalidraw)")

local function get_unique_window(class, program, callback)
	local w = hl.get_window("class:" .. class)
	if w then
		callback(w)
		return
	end
	sub = hl.on("window.open", function(ew)
		if ew.class == class then
			sub:remove()
			callback(ew)
		end
	end)
	hl.dispatch(hl.dsp.exec_cmd(program))
end

local function goto_window(class, program)
	get_unique_window(class, program, function(w)
		hl.dispatch(hl.dsp.focus({ window = w }))
	end)
end

local function pull_window(class, program)
	get_unique_window(class, program, function(w)
		hl.dispatch(hl.dsp.window.move({ window = w, workspace = "e+0" }))
	end)
end

launch(main_mod("CTRL + O"), function()
	goto_window("obsidian", "obsidian")
end, "Focus Obsidian")
launch(main_mod("CTRL + SHIFT + O"), function()
	pull_window("obsidian", "obsidian")
end, "Bring Obsidian to current workspace")

launch(main_mod("D"), function()
	goto_window("discord", "open-discord")
end, "Focus Discord")
launch(main_mod("SHIFT + D"), function()
	pull_window("discord", "open-discord")
end, "Bring Discord to current workspace")

launch(main_mod("N"), "kitty-cwd-launcher neovide", "Open Neovim")

launch(
	main_mod("SHIFT + N"),
	string.format('pkill -f "%s" || %s', nvim_search, nvim_search),
	"Launch FZF in a Kitty panel and open the result in Neovim"
)
launch(main_mod("Escape"), string.format('pkill -f "%s" || %s', btop, btop), "Launch btop in a Kitty panel")
