vim.opt.runtimepath:remove(vim.fn.expand("~/.config/nvim"))
vim.opt.packpath:remove(vim.fn.expand("~/.local/share/nvim"))

vim.opt.runtimepath:append(vim.fn.expand("~/.config/nvchad"))
vim.opt.packpath:append(vim.fn.expand("~/.local/share/nvchad"))

local old_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(value)
  if value == "data" then
    return vim.fn.expand("~/.local/share/nvchad")
  else
    return old_stdpath(value)
  end
end


vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"

vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

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

vim.cmd([[
  aunmenu PopUp.How-to\ disable\ mouse
  aunmenu PopUp.-1-
]])

vim.o.title = true

vim.o.exrc = true
vim.o.secure = true

vim.o.linebreak = true

-- Autocommand to update the title on certain events
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "DirChanged" }, {
  callback = function()
    local filename = vim.fn.expand("%:t")
    local directory = vim.fn.expand("%:p:h")
    vim.o.titlestring = string.format("%s in %s", filename, directory)
  end
})

-- Autocommand to create parent directories of a file if needed
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    return vim.fn.mkdir(vim.fn.expand("<afile>:p:h"), 'p') == true
  end
})

if vim.g.neovide then
  dofile(vim.fn.expand("$XDG_CONFIG_HOME/neovide/neovide.lua"))
end

vim.opt.runtimepath:append("~/Development/neovim/domain.nvim")
require("domain").setup({})

require "virtual_text_diagnostics"
require "markdown_yank"
