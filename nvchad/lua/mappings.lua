require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

-- Map superfluous actions to <Esc>
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("i", "hl", "<ESC>")
map("i", "lh", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
