vim.opt.runtimepath:remove(vim.fn.expand('~/.config/nvim'))
vim.opt.packpath:remove(vim.fn.expand('~/.local/share/nvim'))

vim.opt.runtimepath:append(vim.fn.expand('~/.config/nvchad'))
vim.opt.packpath:append(vim.fn.expand('~/.local/share/nvchad'))

local old_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(value)
	if value == "data" then
		return vim.fn.expand("~/.local/share/nvchad")
	end
	return old_stdpath(value)
end


-- vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.base46_cache = vim.fn.expand('~/.local/share/nvchad/base46/')
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
-- local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
local lazypath = vim.fn.expand('~/.local/share/nvchad/lazy/lazy.nvim')

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.runtimepath:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "options"
    end,
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

if vim.g.neovide then
  dofile(vim.fn.expand('$XDG_CONFIG_HOME/neovide/neovide.lua'))
end
