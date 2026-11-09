local M = {}

vim.api.nvim_set_hl(0, "GitBlame", { link = "DiagnosticVirtualTextInfo", default = true })

local ns = vim.api.nvim_create_namespace("git_blame")
local enabled = {}
local blocks = {}
local pin_win
local pin_src
local pin_text_buf = vim.api.nvim_create_buf(false, true)

local function close_pin()
  if pin_win and vim.api.nvim_win_is_valid(pin_win) then
    vim.api.nvim_win_close(pin_win, true)
  end
  pin_win, pin_src = nil, nil
end

vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(args)
    enabled[args.buf] = nil
    blocks[args.buf] = nil
    if pin_src == args.buf then close_pin() end
  end,
})

local function range(buf)
  if vim.fn.mode():find("[vV\22]") then
    local a, b = vim.fn.line("v"), vim.fn.line(".")
    return math.min(a, b), math.max(a, b)
  end
  return 1, vim.api.nvim_buf_line_count(buf)
end

local function parse(text)
  local entries, entry = {}, nil
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    local sha, lnum = line:match("^%^?(%x+) %d+ (%d+)")
    if sha then
      entry = { sha = sha, lnum = tonumber(lnum) }
      entries[entry.lnum] = entry
    elseif entry then
      entry.author = line:match("^author (.*)") or entry.author
      entry.time = line:match("^author%-time (%d+)") or entry.time
      entry.summary = line:match("^summary (.*)") or entry.summary
    end
  end
  return entries
end

local function format(entry)
  -- Lines from `--contents -` have an all-zero object ID.
  if entry.sha:match("^0+$") then return "Not Committed Yet" end

  local date = entry.time and os.date("%Y-%m-%d", tonumber(entry.time)) or "?"
  return ("%s %s %s %s"):format(entry.sha:sub(1, 7), entry.author or "?", date, entry.summary or "")
end

local function annotate(buf, lnum, text)
  vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, {
    virt_text = { { " " .. text, "GitBlame" } },
    virt_text_pos = "eol",
  })
end

local function render(buf, entries)
  local list = {}
  local lnum = 1

  while lnum <= vim.api.nvim_buf_line_count(buf) do
    local entry = entries[lnum]
    if not entry then
      lnum = lnum + 1
    else
      local last = lnum
      while entries[last + 1] and entries[last + 1].sha == entry.sha do
        last = last + 1
      end

      local text = format(entry)
      list[#list + 1] = { first = lnum, last = last, text = text }
      annotate(buf, lnum, text)

      lnum = last + 1
    end
  end

  blocks[buf] = list
end

local function show_pin(win, buf, lnum, text)
  text = " " .. text
  local win_width = vim.api.nvim_win_get_width(win)
  local width = math.max(1, math.min(vim.fn.strdisplaywidth(text), win_width))

  local pos = vim.fn.screenpos(win, lnum, #vim.fn.getline(lnum) + 1)
  local win_col = vim.fn.win_screenpos(win)[2]
  local col = pos.col > 0 and pos.col - win_col or win_width - width
  col = math.max(0, math.min(col, win_width - width))

  vim.api.nvim_buf_set_lines(pin_text_buf, 0, -1, false, { text })
  local opts = {
    relative = "win",
    win = win,
    row = 0,
    col = col,
    width = width,
    height = 1,
    anchor = "NW",
    border = "none",
    focusable = false,
    style = "minimal",
    noautocmd = true,
    zindex = 50,
  }

  if pin_win and vim.api.nvim_win_is_valid(pin_win) then
    vim.api.nvim_win_set_config(pin_win, opts)
  else
    pin_win = vim.api.nvim_open_win(pin_text_buf, false, opts)
    vim.wo[pin_win].winblend = 100
    vim.wo[pin_win].winhl = "Normal:GitBlame"
    vim.wo[pin_win].wrap = false
  end
  pin_src = buf
end

local function update_pin()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local list = blocks[buf]
  if not list then
    close_pin()
    return
  end

  local top = vim.fn.line("w0", win)
  for _, block in ipairs(list) do
    if top <= block.last then
      if block.first < top then
        show_pin(win, buf, top, block.text)
      else
        close_pin()
      end
      return
    end
  end
end

vim.api.nvim_create_autocmd({ "WinScrolled", "WinEnter", "BufEnter", "VimResized" }, {
  callback = update_pin,
})

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()

  if enabled[buf] then
    enabled[buf] = nil
    blocks[buf] = nil
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    close_pin()
    return
  end

  local data = require("mini.git").get_buf_data(buf)
  local root = data and data.root or vim.fs.root(buf, ".git")
  if not root then
    vim.notify("Not inside a Git repository", vim.log.levels.WARN)
    return
  end

  local line_start, line_end = range(buf)
  local cmd = {
    "git", "-C", root, "blame", "--line-porcelain", "--no-textconv", "--contents", "-",
    "-L", ("%d,%d"):format(line_start, line_end),
    "--", vim.api.nvim_buf_get_name(buf),
  }
  local contents = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), "\n") .. "\n"

  enabled[buf] = true
  vim.system(cmd, { text = true, stdin = contents }, function(res)
    vim.schedule(function()
      if not enabled[buf] then return end
      if res.code ~= 0 then
        enabled[buf] = nil
        vim.notify(res.stderr, vim.log.levels.WARN)
        return
      end
      render(buf, parse(res.stdout))
      update_pin()
    end)
  end)
end

return M
