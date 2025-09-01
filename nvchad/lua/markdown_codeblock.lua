-- Converts the text in a register into a Markdown codeblock, with optional formatting

---@class markdown_codeblock_opts
--- Add a comment containing the name of the file from which the block was yanked, e.g.
--- ```lua
--- -- markdown_yank.lua
--- print("This line is from markdown_yank.lua")
--- ```
--- (Default: `true`)
---@field add_filename_comment? boolean
--- Some platforms use syntax highlighting libraries which don't necessarily support all languages. This lets you map a set of targets or general languages to alternatives which may properly render. It will prompt you to select a platform if you pass it in the `platform = { <mapping> }` format.
--- Example: 
---
--- ```lua
--- {discord = { gdscript = "php" }, jsx = "js" }
--- ```
--- Here are some relevant libraries (containing links to supported languages) and the platforms that use them:
--- - [Prism](https://prismjs.com/#supported-languages)
---     - Obsidian
--- - [Highlight.js](https://github.com/highlightjs/highlight.js/blob/main/SUPPORTED_LANGUAGES.md)
---     - Discord
--- - [Rouge](https://rouge-ruby.github.io/docs/file.Languages.html)
---     - GitHub Markdown
---     - Jekyll Sites
--- (Default: `nil`)
---@field language_name_map? table<string, string|table<string, string>>
--- If a global substitution is found (exlcuding those found in a target), confirm the substitution
--- (Default: `false`)
---@field confirm_language_substitution? boolean
--- The register to pull the code block text from
--- (Default: `"0"` (most recent yank register))
---@field source_register? string
--- The register to put the code block in
--- (Default: `"+"` (system clipboard register))
---@field target_register? string
--- The buffer to use for file info
--- (Default: `0`)
---@field bufnr? integer

---Gets filename as a comment.
---@param filename string
---@param bufnr? integer
---@return string
local function get_comment_line(filename, bufnr)
  if bufnr == nil then bufnr = 0 end
  local commentstr = vim.bo[bufnr].commentstring
  if not commentstr or commentstr == "" then
    commentstr = "# %s" -- fallback
  end
  -- Remove trailing/leading whitespace and trailing "%s"
  local prefix = commentstr:match("^([^%%]*)%%s") or ""
  local suffix = commentstr:match("%%s([^%%]*)$") or ""
  return prefix .. filename .. suffix
end

-- Normalizes indentation around line with least indentation. Example:
-- ```lua
-- ____table.insert(res, s)
-- __end
-- ```
-- would be normalized as
-- ```lua
-- __table.insert(res, s)
-- end
-- ```
---@param lines string[]
local function normalize_indent(lines)
  local min_indent = nil
  local indent_str = " "
  for _, line in ipairs(lines) do
    local indent = line:match("^(%s*)%S")
    if indent then
      min_indent = (not min_indent or #indent < min_indent) and #indent or min_indent
    end
    -- If tab-indentation is being used, change indentation to that
    if indent and indent:match("^	") then
      indent_str = "	"
    end
  end

  if not min_indent or min_indent == 0 then return lines end

  local res = {}
  for _, line in ipairs(lines) do
    local s = line:gsub("^" .. string.rep(indent_str, min_indent), "", 1)
    table.insert(res, s)
  end
  return res
end

---Prompt user to select a mapping from language_name_map
---@param language_name_map table<string, string|table<string, string>>
---@param language string
---@param confirm boolean
---@return string
local function select_language(language_name_map, language, confirm)
  if language_name_map == nil then return language end

  local global_map_result = language_name_map[language]
  if global_map_result ~= nil and type(global_map_result) == "string" then
    if confirm and
      vim.fn.confirm(string.format("Syntax highlight substitution found: %s --> %s. Accept?", language, global_map_result), "&Yes\n&No", 1) ~= 1 then
        return language
      end
    return global_map_result
  end

  local target_mappings_keys = {}
  for k, v in pairs(language_name_map) do
    if type(v) == "table" and v[language] ~= nil then
      table.insert(target_mappings_keys, k)
    end
  end

  if target_mappings_keys ~= nil then
    table.insert(target_mappings_keys, "Other (use current language)")
    local choice
    vim.ui.select(target_mappings_keys, {
      prompt = string.format("A syntax highlight substitution for \"%s\" was found in the following targets. Select a target for this Markdown block:", language),
    }, function(selected)
      choice = selected
    end)

    if choice == "Other (use current language)" or choice == nil then
      return language
    else
      return language_name_map[choice][language]
    end
  end
  return language
end

---@param opts? markdown_codeblock_opts
local function markdown_codeblock(opts)
  opts = opts or {}
  if opts.add_filename_comment == nil then opts.add_filename_comment = true end
  if opts.confirm_language_substitution == nil then opts.confirm_language_substitution = false end
  if opts.source_register == nil then opts.source_register = "0" end
  if opts.target_register == nil then opts.source_register = "+" end
  if opts.bufnr == nil then opts.bufnr = 0 end

  local ft = select_language(opts.language_name_map, vim.bo[opts.bufnr].filetype, opts.confirm_language_substitution)

  local filename = vim.api.nvim_buf_get_name(opts.bufnr)
  filename = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or ""

  local lines = vim.fn.getreg(opts.source_register, 1, true)
  if type(lines) == "string" then lines = { lines } end -- Can this even happen?

  lines = normalize_indent(lines)

  local md_lines = { "```" .. ft }
  if opts.add_filename_comment and filename ~= "" then
    table.insert(md_lines, get_comment_line(filename, opts.bufnr))
  end
  vim.list_extend(md_lines, lines)
  table.insert(md_lines, "```")

  local text = table.concat(md_lines, "\n")
  vim.fn.setreg(opts.target_register, text)
end

---@type markdown_codeblock_opts
local opts = { add_filename_comment = true, language_name_map = { Discord = { gdscript = "php" } }, confirm_language_substitution = false}
vim.keymap.set("n", "<leader>my", function()
  vim.cmd("normal! yy")
  markdown_codeblock(opts)
  print("Yanked as markdown code block to clipboard.")
end, { silent = true, desc = "Yank line as a Markdown code block" })

vim.keymap.set("v", "<leader>my", function()
  vim.cmd("normal! y")
  markdown_codeblock(opts)
  print("Yanked as markdown code block to clipboard.")
end, { silent = true, desc = "Yank block as a Markdown code block" })
