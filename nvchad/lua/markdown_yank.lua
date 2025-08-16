-- WIP. Yanks a block, formats it for markdown, and optinally supplies file info in said block.
-- ```lua
-- -- markdown_yank.lua
-- local function get_comment_line(filename)
--   local commentstr = vim.bo.commentstring
--   if not commentstr or commentstr == "" then
--     commentstr = "# %s" -- fallback
--   end
--   -- Remove trailing/leading whitespace and trailing "%s"
--   local prefix = commentstr:match("^([^%%]*)%%s") or ""
--   local suffix = commentstr:match("%%s([^%%]*)$") or ""
--   return prefix .. filename .. suffix
-- end
-- ```

-- Gets filename as a comment. Must be expanded to allow for full path, if desired.
---@param filename string
---@return string
local function get_comment_line(filename)
  local commentstr = vim.bo.commentstring
  if not commentstr or commentstr == "" then
    commentstr = "# %s" -- fallback
  end
  -- Remove trailing/leading whitespace and trailing "%s"
  local prefix = commentstr:match("^([^%%]*)%%s") or ""
  local suffix = commentstr:match("%%s([^%%]*)$") or ""
  return prefix .. filename .. suffix
end

-- Normalizes indentation around line with least indentation. Example:
--
-- ```lua
--      local s = line:gsub("^" .. string.rep(" ", min_indent), "", 1)
--      table.insert(res, s)
--    end
-- ```
-- would be normalized as
-- ```lua
--    local s = line:gsub("^" .. string.rep(" ", min_indent), "", 1)
--    table.insert(res, s)
--  end
-- ```
---@param lines string[]
local function normalize_indent(lines)
  local min_indent = nil
  for _, line in ipairs(lines) do
    local indent = line:match("^(%s*)%S")
    if indent then
      min_indent = (not min_indent or #indent < min_indent) and #indent or min_indent
    end
    print(line .. tostring(indent))
  end

  if not min_indent or min_indent == 0 then return lines end

  local res = {}
  for _, line in ipairs(lines) do
    local s = line:gsub("^" .. string.rep(" ", min_indent), "", 1)
    table.insert(res, s)
  end
  return res
end

---@param opts table|nil
--- opts = { filename_comment = true }
local function yank_to_md_clipboard(opts)
  opts = opts or {}
  local ft = vim.bo.filetype
  local filename = vim.api.nvim_buf_get_name(0)
  filename = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or ""
  local lines = vim.fn.getreg('0', 1, true) -- Don't understand this. The only hint is the docs: getreg([{regname} [, 1 [, {list}]]]) 
  if type(lines) == "string" then lines = { lines } end -- Can this even happen?
  lines = normalize_indent(lines)
  local md_lines = {}
  table.insert(md_lines, "```" .. ft)
  -- TODO: Expand this to use project root and get full filepath (e.g. nvim/lua/markdown_yank.lua). Maybe expand even more with GitHub URL?
  if opts.filename_comment and filename ~= "" then
    table.insert(md_lines, get_comment_line(filename))
  end
  vim.list_extend(md_lines, lines)
  table.insert(md_lines, "```")
  local text = table.concat(md_lines, "\n")
  vim.fn.setreg("+", text)
  print("Yanked as markdown code block to clipboard.")
end

-- TODO: Figure out more appropriate mappings.
vim.keymap.set("n", "<leader>my", function()
  vim.cmd("normal! yy")
  yank_to_md_clipboard({ filename_comment = true })
end, { silent = true })

vim.keymap.set("v", "<leader>my", function()
  vim.cmd("normal! y")
  yank_to_md_clipboard({ filename_comment = true })
end, { silent = true })
