vim.g.mapleader = " "

-- Append our scripts and (if not from the Nix store) argv[1] so that scripts are run with the same version
vim.env.PATH = vim.fn.stdpath("config") .. "/scripts:"
    .. (not vim.v.argv[1]:find("^/nix/store/") and (vim.fn.fnamemodify(vim.v.argv[1], ':h') .. ":") or "")
    -- Enable Kitty shell wrappers for terminal emulator integration (OSC 133)
    .. vim.fn.expand("$XDG_CONFIG_HOME/kitty/wrappers") .. ":"
    .. vim.env.PATH

vim.o.shell = vim.o.shell:match("([^/\\]+)$")

require("frontend")
require("autocmds")
require("options")
