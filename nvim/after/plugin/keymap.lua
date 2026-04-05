local map = vim.keymap.set

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to window above" })
map("n", "<C-k>", "<C-w>k", { desc = "Go window below" })

map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Go to type definition" })

-- TODO: Conditionally map this when in terminal that supports <C-Esc>
map("t", "<C-Esc>", "<C-\\><C-N>", { desc = "Exit terminal mode" })

map("n", "<leader>n", function()
  vim.o.number = not vim.o.number or vim.o.relativenumber
  vim.o.relativenumber = vim.o.number and not vim.o.relativenumber
end, { desc = "Cycle between enabled, relative, and disabled line number" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear search highlights" })

-- See :help <Tab>
map("n", "<C-m>", "<C-m>")
map("n", "<C-i>", "<C-i>")

map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

map("n", "<C-w><C-m>", function()
  vim.cmd([[
    let longest = max(map(range(1, line('$')), "virtcol([v:val, '$'])"))
    exec "vertical resize " . (longest + 4)
  ]])
end, { silent = true, desc = "Resize window horizontally to size of longest line" })

map("n", "<leader>ft", "<cmd>Telescope filetypes<CR>", { desc = "Telscope set filetype" })

---@type markdown_codeblock_options
local markdown_codeblock_opts = {
  add_filename_comment = true,
  source_register = "+",
  language_name_map = { Discord = { gdscript = "php" } },
  confirm_language_substitution = false,
}

map("v", "<leader>my", function()
  vim.cmd("y+")
  require("utils.markdown_codeblock").markdown_codeblock(markdown_codeblock_opts)
  print("Yanked as markdown code block to clipboard.")
end, { silent = true, desc = "Yank block and format as Markdown code block" })

map("n", "<leader>my", function()
  vim.cmd("%y+")
  require("utils.markdown_codeblock").markdown_codeblock(markdown_codeblock_opts)
  print("Yanked as markdown code block to clipboard.")
end, { silent = true, desc = "Yank file and format as Markdown code block" })

map("n", "<leader>mk", ":make<CR>", { desc = "Run makeprg" })

-- Replaces :ascii
map({ "n", "x", "o" }, "ga", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.inner", "textobjects")
end, { silent = true, desc = "jump to next function argument" })
map({ "n", "x", "o" }, "gA", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.inner", "textobjects")
end, { silent = true, desc = "jump to previous function argument" })

local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

map({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
map({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
map({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
map({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
map({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
map({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

-- See block related to #38558
local function reset_vmode()
  local mode = vim.fn.mode()
  if mode ~= "x" and mode ~= "v" and mode ~= "o" then
    vim.cmd.normal({ "v\27", bang = true })
  end
end

-- Idea attribution: https://www.reddit.com/r/neovim/comments/1s9q0pi/comment/oduz87k
map({ "n", "x", "o" }, "<CR>", function()
  reset_vmode()
  if vim.fn.mode() == "n" then
    require("vim.treesitter._select").select_child(vim.v.count1)
  else
    require("vim.treesitter._select").select_parent(vim.v.count1)
  end
end, { desc = "Expand node selection" })

map({ "n", "x", "o" }, "<BS>", function()
  reset_vmode()
  if vim.treesitter.get_parser(nil, nil, { error = false }) then
    require("vim.treesitter._select").select_child(vim.v.count1)
  else
    vim.lsp.buf.selection_range(vim.v.count1)
  end
end, { desc = "Shrink node selection" })

-- Replacements for some new builtins; when #38558 is available (likely v0.12.1), these (and reset_vmode) can be removed
do
  map({ "x" }, "[n", function()
    reset_vmode()
    require("vim.treesitter._select").select_prev(vim.v.count1)
  end, { desc = "Select previous node" })

  map({ "x" }, "]n", function()
    reset_vmode()
    require("vim.treesitter._select").select_next(vim.v.count1)
  end, { desc = "Select next node" })

  map({ "x", "o" }, "an", function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      reset_vmode()
      require("vim.treesitter._select").select_parent(vim.v.count1)
    else
      vim.lsp.buf.selection_range(vim.v.count1)
    end
  end, { desc = "Select parent (outer) node" })

  map({ "x", "o" }, "in", function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      reset_vmode()
      require("vim.treesitter._select").select_child(vim.v.count1)
    else
      vim.lsp.buf.selection_range(-vim.v.count1)
    end
  end, { desc = "Select child (inner) node" })
end

vim.keymap.set({ "n", "x" }, "<leader>fm", function()
  require("conform").format({ lsp_fallback = true })
end, { desc = "Format file" })

vim.cmd("packadd nvim.undotree")
map("n", "<leader>u", function()
  require("undotree").open({
    command = math.floor(vim.api.nvim_win_get_width(0) / 3) .. "vnew",
  })
end, { desc = "Toggle undotree" })

do
  local function unlearn(mode, key, msg)
    vim.keymap.set(mode, key, function()
      vim.notify(msg, vim.log.levels.WARN)
    end)
  end

  unlearn("n", "<up>", "Use k instead")
  unlearn("n", "<down>", "Use j instead")
  unlearn("n", "<left>", "Use l instead")
  unlearn("n", "<right>", "Use h instead")
end
