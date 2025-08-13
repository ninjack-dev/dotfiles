-- This is the more verbose version which I've kept for posterity and potential explanation.
-- Sort the `servers` table alphabetically in lspconfig.lua
local function sort_servers_table()
  local target_file = vim.fn.getcwd() .. "/lua/configs/lspconfig.lua"
  local bufnr = vim.fn.bufnr(target_file, true)
  if bufnr == -1 then
    vim.notify("lspconfig.lua not found in current directory", vim.log.levels.ERROR)
    return
  end

  vim.fn.bufload(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "lua")
  local tree = parser:parse()[1]
  local root = tree:root()

  ---@type TSNode
  local servers_node

  -- TODO: Refactor to check for specified structure on each child directly.
  for node, name in root:iter_children() do
    if name == "local_declaration" then
      local assignment_node = node:child(1)
      if assignment_node ~= nil and assignment_node:type() == "assignment_statement" then
        local name_node = assignment_node:child(0)
        if name_node ~= nil and name_node:type() == "variable_list" then
          if vim.treesitter.get_node_text(name_node, bufnr) == "servers" then
            servers_node = assignment_node
            break
          end
        end
      end
    end
  end

  if not servers_node then
    vim.notify("No 'servers' table found in lspconfig.lua", vim.log.levels.ERROR)
    return
  end

  -- Find the table constructor
  local value_node = servers_node:child(2)

  ---@type TSNode[]
  local table_node
  if value_node and value_node:type() == "expression_list" then
    table_node = value_node:field("value") and value_node:field("value")[1]
    if not (table_node and table_node:type() == "table_constructor") then
      vim.notify("No table found for 'servers'", vim.log.levels.ERROR)
      return
    end
  else
    vim.notify("Malformed 'servers' assignment", vim.log.levels.ERROR)
    return
  end


  -- Extract entries
  local entries = {}
  for entry in table_node:iter_children() do
    if entry:type() == "field" then
      local key_node = entry:field("name")[1] and entry:field("name")[1]
      if value_node == nil then
        vim.notify("Somehow, a field didn't have a name.", vim.log.levels.ERROR)
        return
      end
      table.insert(entries, { key = vim.treesitter.get_node_text(key_node, bufnr), entry = entry })
    end
  end

  -- Sort entries by key
  table.sort(entries, function(a, b)
    return a.key < b.key
  end)

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

vim.api.nvim_create_user_command('SortLspServers', sort_servers_table, {})
