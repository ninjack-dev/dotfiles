hl.bind(main_mod("M"), hl.dsp.submap("mark_mode"), { description = "Enter mark mode" })

hl.define_submap("mark_mode", "reset", function()
	for char in string.gmatch("abcdefghijklmnopqrstuvwxyz", ".") do
		hl.bind(char, function()
			local w = hl.get_window("tag:" .. char)
			if w ~= nil then
				hl.dispatch(hl.dsp.window.tag({ tag = "-" .. char, window = w }))
			end
			hl.dispatch(hl.dsp.window.tag({ tag = "+" .. char }))
		end, { description = "Mark window with tag " .. char })
	end
	hl.bind("escape", hl.dsp.submap("reset"), { description = "Exit mark mode" })
end)

hl.bind(main_mod("apostrophe"), hl.dsp.submap("jump_mode"), { description = "Enter jump mode" })

-- TODO: Determine a better location for this.
local ordinal = dofile(os.getenv("XDG_CONFIG_HOME") .. "/nvim/lua/utils/display_utils.lua").ordinal

hl.define_submap("jump_mode", "reset", function()
	for char in string.gmatch("abcdefghijklmnopqrstuvwxyz", ".") do
		hl.bind(char, hl.dsp.focus({ window = "tag:a" }), { description = "Mark window with tag " .. char })
	end

	for i = 1, 10 do
		local key = i % 10
		hl.bind(tostring(key), function()
			for _, w in ipairs(hl.get_windows()) do
				if w.focus_history_id == i - 1 then
					hl.dispatch(hl.dsp.focus({ window = w }))
					return
				end
			end
		end, { description = string.format("Jump to %s most recent window", ordinal(i)) })
	end

	hl.bind("escape", hl.dsp.submap("reset"), { description = "Exit jump mode" })
end)
