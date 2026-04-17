local M = {}

local bufnr_by_index = {}
local index_by_bufnr = {}

function M.update_list()
  bufnr_by_index = {}
  index_by_bufnr = {}
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  for i, b in ipairs(bufs) do
    bufnr_by_index[i] = b.bufnr
    index_by_bufnr[b.bufnr] = i
  end
end

function M.by_index(i)
  return bufnr_by_index[i]
end

function M.by_bufnr(i)
  return index_by_bufnr[i]
end

return M
