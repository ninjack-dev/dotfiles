hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "auto",
	scale = "1.2",
})

-- Dock monitors
hl.monitor({
	output = "desc:HKC OVERSEAS LIMITED 24E3 0000000000001",
	mode = "preferred",
	position = "1600x-400",
	scale = "1",
})
hl.monitor({
	output = "desc:Sceptre Tech Inc Sceptre M24 00",
	mode = "preferred",
	position = "3520x-875",
	scale = "1",
	transform = 3,
})

hl.env("XCURSOR_SIZE", "24")

local keyboards = {
"at-translated-set-2-keyboard",
"at-translated-set-2-keyboard-kanata"
}

hl.bind("CTRL + XF86AudioMute", hl.dsp.exec_cmd("playerctl previous"), {
	description = "Skip to previous media track",
	device = { inclusive = true, list = keyboards },
})
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("playerctl play-pause"), {
	description = "Play/pause current media track",
	device = { inclusive = true, list = keyboards },
})
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("playerctl next"), {
	description = "Skip to next media track",
	device = { inclusive = true, list = keyboards },
})

hl.gesture({
	fingers = 3,
	action = "workspace",
	direction = "horizontal",
})

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

-- Amazon Basics mouse
hl.device({
  name = "chicony-wireless-device-2",
  sensitivity = -0.7
})
