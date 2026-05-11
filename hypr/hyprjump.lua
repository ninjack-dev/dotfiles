local M = {
	jump_list = {},
	mark_mode = {},
}

---Returns a number as an ordinal string, e.g. 1st, 23rd
---@param i integer
---@return string
local function ordinal(i)
	local ordinal_suffixes = {
		["1"] = "st",
		["2"] = "nd",
		["3"] = "rd",
		["11"] = "th",
		["12"] = "th",
		["13"] = "th",
		["14"] = "th",
		["15"] = "th",
		["16"] = "th",
		["17"] = "th",
		["18"] = "th",
		["19"] = "th",
	}
	local str = tostring(i)
	local suffix = ordinal_suffixes[str:sub(-2)] or ordinal_suffixes[str:sub(-1)] or "th"
	return str .. suffix
end

-- Jump List
do
	---@type (HL.Window)[]
	local jump_list = {}
	local jump_idx = 1
	local in_transition = false

	local function build_jump_list()
		jump_list = hl.get_windows()
		table.sort(jump_list, function(w1, w2)
			return w1.focus_history_id < w2.focus_history_id
		end)
		jump_idx = 1
	end

	local jump_funcs = {}

	---Jump forward through window history
	function jump_funcs.jump_up()
		if jump_idx <= 1 then
			return
		end
		jump_idx = jump_idx - 1
		in_transition = true
		hl.dispatch(hl.dsp.focus({ window = jump_list[jump_idx] }))
	end

	---Jump backward through window history
	function jump_funcs.jump_down()
		if jump_idx == #jump_list then
			return
		end
		jump_idx = jump_idx + 1
		in_transition = true
		hl.dispatch(hl.dsp.focus({ window = jump_list[jump_idx] }))
	end

	---Initialize Hyprjump's jump list. Returns a table with the two necessary functions for jumping through the window focus history.
	function M.jump_list.setup()
		build_jump_list()

		hl.on(
			"window.active",
			---@param w HL.Window
			function(w)
				local on_blank_workspace = w.address == nil -- Jumping to blank workspace produces this event, but with an empty window
				local on_target = w.address == jump_list[jump_idx > 0 and jump_idx or 1].address -- The event can fire twice occasionally

				if on_blank_workspace or (not in_transition and not on_target) then
					build_jump_list()
					if on_blank_workspace then
						jump_idx = 0
					end
				elseif on_target then
					in_transition = false
				end
			end
		)

		return jump_funcs
	end
end

-- Mark Mode
do
	---@class MarkModeOpts
	---@field tag_prefix? string Prefix for mark tags. Default: ""
	---@field breakout_key? string Key used safely to exit mark/jump modes. Default: "escape"
	---@field mark_mode_submap_name? string Name of the mark mode submap. Default: "mark_mode"
	---@field jump_mode_submap_name? string Name of the jump mode submap. Default: "jump_mode"
	---@field normalize? boolean If true, map 0 to the 10th recent window, otherwise map it to the 1st, with each number key being shifted accordingly. Default: true

	---Initialize Hyperjump's mark mode. Returns a table with the two necessary dispatchers for entering mark mode and jump mode.
	---@param opts? MarkModeOpts
	function M.mark_mode.setup(opts)
		opts = opts or {}
		local tag_prefix = opts.tag_prefix or ""
		local breakout_key = opts.breakout_key or "escape"
		local mark_mode_submap_name = opts.mark_mode_submap_name or "mark_mode"
		local jump_mode_submap_name = opts.jump_mode_submap_name or "jump_mode"
		local normalize = (opts.normalize == nil and true) or opts.normalize

		hl.define_submap(mark_mode_submap_name, "reset", function()
			for char in string.gmatch("abcdefghijklmnopqrstuvwxyz", ".") do
				hl.bind(char, function()
					local w = hl.get_window("tag:" .. tag_prefix .. char)
					if w ~= nil then
						hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tag_prefix .. char, window = w }))
					end
					hl.dispatch(hl.dsp.window.tag({ tag = "+" .. tag_prefix .. char }))
				end, { description = "Mark window with tag " .. tag_prefix .. char })
			end
			hl.bind(breakout_key, function() end, { description = "Exit mark mode" })
		end)

		hl.define_submap(jump_mode_submap_name, "reset", function()
			for char in string.gmatch("abcdefghijklmnopqrstuvwxyz", ".") do
				hl.bind(
					char,
					hl.dsp.focus({ window = "tag:" .. tag_prefix .. char }),
					{ description = "Jump to window with tag " .. tag_prefix .. char }
				)
			end

			for i = 1, 10 do
				local key = i % 10

				local ordinal_index = ""
				if (normalize and i - 1 or key) >= 1 then
					ordinal_index = " " .. ordinal(normalize and i or i + 1)
				end

				hl.bind(tostring(key), function()
					for _, w in ipairs(hl.get_windows()) do
						if w.focus_history_id == (normalize and i - 1 or key) then
							hl.dispatch(hl.dsp.focus({ window = w }))
							return
						end
					end
				end, { description = string.format("Jump to%s most recent window", ordinal_index) })
			end

			hl.bind(breakout_key, function() end, { description = "Exit jump mode" })
		end)

		return {
			enter_mark_mode = hl.dsp.submap(mark_mode_submap_name),
			enter_jump_mode = hl.dsp.submap(jump_mode_submap_name),
		}
	end
end

return M
