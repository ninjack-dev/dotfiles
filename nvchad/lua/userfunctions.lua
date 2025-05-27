local M = {}

-- Constantly execute an action while inside the line range
function M.domain(line_1, line_2, action)
  -- Remove leading/trailing whitespace
  action = action:match("^%s*(.-)%s*$")
  vim.api.nvim_win_set_cursor(0, { line_1, vim.api.nvim_win_get_cursor(0)[2] })

  while true do
    local prev = vim.api.nvim_win_get_cursor(0)
    local prev_buf_lines = vim.api.nvim_buf_line_count(0)

    vim.cmd.normal { action, bang = true }

    local curr = vim.api.nvim_win_get_cursor(0)
    local curr_buf_lines = vim.api.nvim_buf_line_count(0)
    if curr[1] == prev[1]
        and curr_buf_lines >= prev_buf_lines then
      vim.api.nvim_echo(
      { { "Infinite loop detected: action " .. action .. " does not move the cursor or shrink the buffer past this point." } }, true,
        { err = true })
      break
    end
    if curr[1] == line_2 then break end
    if curr[1] > line_2 then break end
  end
end

vim.api.nvim_create_user_command(
  "Domain",
  function(opts)
    M.domain(opts.line1, opts.line2, opts.args)
  end,
  { range = true, nargs = 1 }
)

vim.api.nvim_create_user_command(
  "Domain",
  function(opts)
    M.domain(opts.line1, opts.line2, opts.args)
  end,
  { range = true, nargs = 1 }
)

return M
