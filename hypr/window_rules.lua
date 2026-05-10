local wr = hl.window_rule

wr({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

wr({
	name = "no-fullscreen-rounding",
	match = { fullscreen = true },
	rounding = 0,
})

wr({
	name = "maximize-discord-on-startup",
	match = {
		class = "^discord$",
	},
	maximize = true,
})

wr({
	name = "float-and-pin-pip",
	match = {
		title = "^Picture in picture$",
	},
	float = true,
	pin = true,
	no_blur = true,
	keep_aspect_ratio = true,
})

wr({
	name = "character-map",
	match = {
		title = "^Character Map$",
	},
	float = true,
})

local lr = hl.layer_rule

lr({
	name = "slurp",
	match = { namespace = "selection" },
	animation = "fade",
})

lr({
	name = "kitty-panels",
	match = { namespace = "kitty-panel" },
	animation = "slide top",
	order = 1,
})

lr({
	name = "gtk-widgets",
	match = { namespace = "gtk-layer-shell" },
	animation = "slide top",
})

lr({
	name = "hyprpricker",
	match = { namespace = "hyprpicker" },
	no_anim = true,
})
