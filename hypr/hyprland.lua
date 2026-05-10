---@diagnostic disable: lowercase-global

terminal = "kitty-cwd-launcher kitty"
file_manager = "dolphin"
browser = "brave"
browser_private = "brave --incognito"
calculator = "qalculate-gtk"
character_map = "gucharmap"

--- Kitty Panels
nvim_search = "kitty +kitten panel --lines 10 --focus-policy on-demand --layer top nvim_search.sh"
btop = "kitty +kitten panel --lines 30 --focus-policy on-demand --layer top btop"

--- Rofi Menus
menu =
	'rofi -show combi -combi-modes "hl-window,drun" -modes "hl-window:~/.config/rofi/scripts/hyprland_window_switcher.sh"'
workspace_renamer =
	'rofi -show "hl-workspace-rename" -modes "hl-workspace-rename:~/.config/rofi/scripts/rename_workspace.sh"'

hl.on("hyprland.start", function()
	hl.exec_cmd("hypridle")
	hl.exec_cmd("astal-tray --daemonize")
	hl.exec_cmd("astal-notifd --daemonize")

	hl.exec_cmd("nm-applet ")
	hl.exec_cmd("discord --start-minimized ")
	hl.exec_cmd("udiskie")
	hl.exec_cmd("syncthingtray --wait")
	hl.exec_cmd("brave --enable-features=TouchpadOverscrollHistoryNavigation")
	hl.exec_cmd("kdeconnect-indicator")
	hl.exec_cmd("aw-qt")
	hl.exec_cmd("netbird-ui")
	hl.exec_cmd("ags run ~/.config/ags/notifications/ &")
	hl.exec_cmd("ags run ~/.config/ags/bar/ &")
end)

hl.env("GTK_THEME", "Nordic")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("NVIM_APPNAME", "nvim")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk2")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Look & Feel

hl.config({
	general = {
		layout = "dwindle",

		gaps_in = 0,
		gaps_out = 0,

		border_size = 2,

		-- Using Nord (https://www.nordtheme.com/docs/colors-and-palettes)
		col = {
			active_border = {
				-- Nord Frost (nord4 - nord6)
				colors = { "#8FBCBBee", "#88C0D0ee", "#81A1C1ee", "#5E81ACee" },
				angle = 90,
			},
			inactive_border = "#2E3440aa", -- Nord Polar Night (nord0)
		},

		resize_on_border = false,
		allow_tearing = false,
	},

	decoration = {
		rounding = 10,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	dwindle = {
		preserve_split = true,
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		focus_on_activate = true,
		on_focus_under_fullscreen = 1,
		enable_anr_dialog = false,
    disable_splash_rendering = true,
	},

	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_options = "ctrl:nocaps",
		kb_model = "",
		kb_rules = "",

		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			scroll_factor = 0.6,
		},
	},

	render = {
		direct_scanout = 1,
	},

	binds = {
		movefocus_cycles_fullscreen = true,
	},
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("easeInOutExpo", { type = "bezier", points = { { 0.87, 0 }, { 0.13, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "easeInOutExpo" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "myBezier", style = "slide left" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "myBezier", style = "slide bottom" })

require("keymap")
require("window_rules")
require("lenovo_e14")
