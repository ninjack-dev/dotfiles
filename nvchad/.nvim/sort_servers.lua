-- Sort the `servers` table alphabetically in lspconfig.lua
-- This is the "magic numbers" version which works and is half the size, but it's near impossible to read.
-- TOOD: Wrap in pcall(). Just in case.
local function sort_servers_table()
  local bufnr = vim.fn.bufnr("lua/configs/lspconfig.lua", true)
  -- local bufnr = vim.fn.bufnr(vim.fn.getcwd() .. "/lua/configs/lspconfig.lua", true)
  if bufnr == -1 then
    vim.notify("lspconfig.lua not found in current directory", vim.log.levels.ERROR)
    return
  end

  vim.fn.bufload(bufnr)
  local root = vim.treesitter.get_parser(bufnr, "lua"):parse()[1]:root()

  ---@type TSNode
  local table_node

  local entries = {}
  for _, v in ipairs(root:field("local_declaration")) do
    if vim.treesitter.get_node_text(v:child(1):child(0):field("name")[1], bufnr) == "servers" and
        v:child(1):child(2) and v:child(1):child(2):type() == "expression_list" then
      table_node = v:child(1):child(2):field("value")[1]
      for entry in table_node:iter_children() do
        if entry:type() == "field" then
          table.insert(entries, { key = vim.treesitter.get_node_text(entry:field("name")[1], bufnr), entry = entry })
        end
      end
      table.sort(entries, function(a, b) return a.key < b.key end)
      break
    end
  end

  -- Reconstruct table text
  local new_table_lines = {}
  for _, entry in ipairs(entries) do
    local _, start_column, _, _ = entry.entry:range()
    for s in (vim.treesitter.get_node_text(entry.entry, bufnr):gsub("^%s*", string.rep(" ", start_column)) .. ','):gmatch("[^\r\n]+") do
      table.insert(new_table_lines, s) -- Strip indentation and re-add
    end
  end

  local start_row, _, end_row, _ = table_node:range()
  vim.api.nvim_buf_set_lines(bufnr, start_row + 1, end_row, false, new_table_lines)

  vim.notify("Sorted servers table in lspconfig.lua")
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "lua/configs/lspconfig.lua", -- relative to CWD or use full path
  callback = sort_servers_table,
})
