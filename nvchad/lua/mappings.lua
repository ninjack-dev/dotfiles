require "nvchad.mappings"
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
map('n', '<leader>ft', "<cmd>Telescope filetypes<CR>", { desc = 'Telscope set filetype'})

---@type markdown_codeblock_opts
local markdown_codeblock_opts = { add_filename_comment = true, language_name_map = { Discord = { gdscript = "php" } }, confirm_language_substitution = false}

map("n", "<leader>my", function()
  vim.cmd("normal! yy")
  require("markdown_codeblock").markdown_codeblock(markdown_codeblock_opts)
  print("Yanked as markdown code block to clipboard.")
end, { silent = true, desc = "Yank line as a Markdown code block" })

map("v", "<leader>my", function()
  vim.cmd("normal! y")
  require("markdown_codeblock").markdown_codeblock(markdown_codeblock_opts)
  print("Yanked as markdown code block to clipboard.")
end, { silent = true, desc = "Yank block as a Markdown code block" })