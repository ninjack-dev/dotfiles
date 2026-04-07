if vim.g.neovide then
  vim.g.neovide_scale_factor = 0.85
  vim.g.neovide_input_ime = true
  vim.g.neovide_hide_mouse_when_typing = true

  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  vim.keymap.set("n", "<C-=>", function()
    change_scale_factor(1.15)
  end)
  vim.keymap.set("n", "<C-->", function()
    change_scale_factor(1 / 1.15)
  end)

  local function copy()
    vim.cmd([[normal! "+y]])
  end
  local function paste()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end
  vim.keymap.set("v", "<C-S-c>", copy, { silent = true, desc = "Neovide - Copy to system clipboard" })
  vim.keymap.set(
    { "n", "i", "v", "c", "t" },
    "<C-S-v>",
    paste,
    { silent = true, desc = "Neovide - Paste from system clipboard" }
  )
elseif vim.env.TERM:match("kitty") then
  -- Adapted from bg.nvim https://github.com/typicode/bg.nvim/blob/main/plugin/bg.lua, modded to allow :restart
  local cmdstr = function(s)
    return vim.split(s, " ", {})
  end

  local update_count = 0
  ---@type uv.uv_tty_t|nil
  local tty = nil

  local reset = function()
    if tty == nil then
      return
    end
    vim.system(cmdstr("kitty @ set-spacing padding=default margin=default"))
    if os.getenv("TMUX") then
      tty:write("\x1bPtmux;\x1b\x1b]111\x07\x1b\\")
    end
    for _ = 1, update_count do
      tty:write("\x1b]30101\x07")
    end
  end

  local update = function()
    if tty == nil then
      return
    end
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false, create = false })
    local bg = normal.bg
    local fg = normal.fg
    if bg == nil then
      return reset()
    end

    local bghex = string.format("#%06x", bg)
    local fghex = string.format("#%06x", fg)

    tty:write("\x1b]30001\x07")

    if os.getenv("TMUX") then
      tty:write("\x1bPtmux;\x1b\x1b]11;" .. bghex .. "\x07\x1b\\")
      tty:write("\x1bPtmux;\x1b\x1b]12;" .. fghex .. "\x07\x1b\\")
    else
      tty:write("\x1b]11;" .. bghex .. "\x07")
      tty:write("\x1b]12;" .. fghex .. "\x07")
    end

    update_count = update_count + 1
  end

  local init = function()
    tty = vim.uv.new_tty(1, false)
    if tty == nil then
      return
    end
    vim.system(cmdstr("kitty @ set-spacing padding=0 margin=0"), {}, function() end) -- Run async to save ~50ms
    update()
  end

  vim.api.nvim_create_autocmd({ "UIEnter" }, { callback = init })
  vim.api.nvim_create_autocmd({ "ColorScheme" }, { callback = update })
  vim.api.nvim_create_autocmd({ "UILeave" }, { callback = reset })

  vim.system({ 'cat' }, function () end) -- Apply workaround listed in #38836
end
