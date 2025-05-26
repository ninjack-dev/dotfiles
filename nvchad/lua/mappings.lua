require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map('i', '<C-BS>', '<C-o>db', { noremap = true, silent = true })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
