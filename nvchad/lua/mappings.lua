require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("i", "<C-BS>", "<C-w>", { noremap = true, silent = true, desc = "Delete backwards by a word (same as <C-w>)"})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
