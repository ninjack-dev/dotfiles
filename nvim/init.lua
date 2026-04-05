vim.g.mapleader = " "

vim.env.PATH =
  -- Prepend utility scripts
  (vim.fn.stdpath("config") .. "/scripts:")
  -- Prepend argv[1] (if not from /nix/store, which uses wrappers) so that scripts are run with the same version
  .. (not vim.v.argv[1]:find("^/nix/store/") and (vim.fn.fnamemodify(vim.v.argv[1], ":h") .. ":") or "")
  -- Enable Kitty shell wrappers for terminal emulator integration (OSC 133)
  .. (vim.fn.expand("$XDG_CONFIG_HOME/kitty/wrappers") .. ":")
  .. vim.env.PATH

vim.o.shell = vim.o.shell:match("([^/\\]+)$")

require("frontend")
require("autocmds")
require("options")
