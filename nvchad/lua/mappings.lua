require "nvchad.mappings"
local builtin = require("telescope.builtin")
local map = vim.keymap.set

map("i", "<C-BS>", "<C-w>", { noremap = true, silent = true, desc = "Delete backwards by a word (same as <C-w>)" })

-- See :help <Tab>
map("n", "<C-m>", "<C-m>")
map("n", "<C-i>", "<C-i>")

map("n", "<C-w><C-m>", function()
  vim.cmd([[
    let longest = max(map(range(1, line('$')), "virtcol([v:val, '$'])"))
    exec "vertical resize " . (longest + 4)
  ]])
end, { silent = true, desc = "Shrink window to size of longest line."}
)

-- TODO - Replace this if/when Telescope gets replaced
map('n', '<leader>st', "<cmd>Telescope filetypes<CR>", { desc = 'Telscope set filetype'})
