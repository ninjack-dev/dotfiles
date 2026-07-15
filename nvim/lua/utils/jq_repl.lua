---JQ REPL for Neovim.
---
---Provides a split-window interface for interactively writing and testing jq
---expressions against a JSON document in real time
---
---Usage:
---  :JQrepl                 -- use current buffer (filetype must be "json")
---  :JQrepl data.json       -- open a file as the JSON source
---  :JQreplClose            -- tear down the REPL windows
---
---To set a custom debounce, pass `debounce_ms` to start():
---  :lua require('utils.jq_repl').start({ file='data.json', debounce_ms=400 })
local M = {}

local default_debounce_ms = 300

---@class JQReplState
---@field jq_buf integer|nil
---@field jq_win integer|nil
---@field json_buf integer|nil
---@field json_win integer|nil
---@field preview_buf integer|nil
---@field preview_win integer|nil
---@field debounce_timer uv.uv_timer_t|nil
---@field debounce_ms integer
---@field closing boolean
local state = {
  jq_buf = nil,
  jq_win = nil,
  json_buf = nil,
  json_win = nil,
  preview_buf = nil,
  preview_win = nil,
  debounce_timer = nil,
  debounce_ms = default_debounce_ms,
  closing = false,
}

local augroup = nil

local function has_jq()
  return vim.fn.executable("jq") == 1
end

---Return the full text of a buffer as a single string.
---@param bufnr integer
---@return string
local function buf_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end

local function cancel_debounce()
  if state.debounce_timer then
    state.debounce_timer:close()
    state.debounce_timer = nil
  end
end

---Read the buffer currently displayed in a tracked window, or nil.
---We resolve at runtime so we never hold stale references.
---@param win_field string  key in `state` for the window ID
---@return integer|nil
local function win_current_buf(win_field)
  local win = state[win_field]
  if not win or not vim.api.nvim_win_is_valid(win) then return nil end
  return vim.api.nvim_win_get_buf(win)
end

local function do_update_preview()
  -- Resolve buffers at runtime from the tracked windows.
  local jq_buf = win_current_buf("jq_win")
  local json_buf = win_current_buf("json_win")
  local preview_buf = win_current_buf("preview_win")

  -- Sync the cached state so is_active() and other readers stay correct.
  state.jq_buf = jq_buf
  state.json_buf = json_buf
  state.preview_buf = preview_buf

  if not jq_buf or not json_buf or not preview_buf then return end

  local expression = buf_text(jq_buf):gsub("[\n\r]+$", "")

  -- Empty expression: fall back to identity filter so jq formats the output.
  if expression == "" then
    expression = "."
  end

  local obj = vim.system(
    { "jq", "--monochrome-output", expression },
    {
      stdin = true,
      text = true,
    },
    function(result)
      -- `preview_buf` is an integer captured by closure; it won't change
      -- between now and when the callback fires, so we use it directly.
      local pbuf = preview_buf
      vim.schedule(function()
        if not pbuf or not vim.api.nvim_buf_is_valid(pbuf) then
          return
        end

        local lines
        if result.code == 0 and result.stdout then
          lines = vim.split(result.stdout, "\n", { plain = true })
          -- Trim trailing empty line that jq always emits.
          if #lines > 0 and lines[#lines] == "" then
            table.remove(lines)
          end
        elseif result.stderr and result.stderr ~= "" then
          lines = vim.split(result.stderr, "\n", { plain = true })
        else
          lines = { "jq: exited with code " .. tostring(result.code) }
        end

        vim.bo[pbuf].modifiable = true
        vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
        vim.bo[pbuf].syntax = result.code == 0 and "json" or "OFF"
        vim.bo[pbuf].modifiable = false
      end)
    end
  )

  -- Write buffer lines one by one to the pipe instead of concatenating
  -- into one giant string, keeping peak memory lower for large buffers.
  local lines = vim.api.nvim_buf_get_lines(json_buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if i > 1 then
      obj:write("\n")
    end
    obj:write(line)
  end
  obj:write(nil) -- close stdin → jq processes and exits
end

local function debounced_update()
  cancel_debounce()
  state.debounce_timer = vim.defer_fn(function()
    state.debounce_timer = nil
    do_update_preview()
  end, state.debounce_ms)
end

---Create a scratch buffer and open it in a split relative to a parent window.
---This is a thin wrapper around nvim_create_buf + nvim_open_win that cuts
---the repetition in create_layout().
---@param opts { name: string, split: string, target_win: integer, bo?: table, wo?: table }
---@return integer buf, integer win
local function create_scratch_pane(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, opts.name)
  for k, v in pairs(opts.bo or {}) do
    vim.bo[buf][k] = v
  end

  local win = vim.api.nvim_open_win(buf, false, {
    split = opts.split,
    win = opts.target_win,
  })
  for k, v in pairs(opts.wo or {}) do
    vim.wo[win][k] = v
  end

  return buf, win
end

---Create the three-buffer split layout.
---Uses nvim_open_win for split windows so the returned window ID is always the
---newly-created window, avoiding the confusion of :split cursor positioning.
local function create_layout()
  -- Preview window: vertical split to the right of the JSON source window.
  local preview_buf, preview_win = create_scratch_pane({
    name = "[JQ Preview]",
    split = "right",
    target_win = state.json_win,
    bo = { buftype = "nofile", bufhidden = "wipe", swapfile = false, modifiable = false, buflisted = false },
    wo = { number = false, relativenumber = false, winfixbuf = true },
  })
  state.preview_buf = preview_buf
  state.preview_win = preview_win

  -- JQ window: horizontal split above the JSON source window.
  local jq_buf, jq_win = create_scratch_pane({
    name = "[JQ Expression]",
    split = "above",
    target_win = state.json_win,
    -- "hide" instead of "wipe" so the scratch buffer stays in the list
    -- when the user opens a .jq file in the expression window.  The
    -- scratch buffer can be found again via :bnext / :ls.
    bo = { buftype = "nofile", bufhidden = "hide", swapfile = false, buflisted = true, filetype = "jq" },
    wo = { number = false, relativenumber = false },
  })
  state.jq_buf = jq_buf
  state.jq_win = jq_win
end

---Wire up autocommands for the live-update loop and cleanup.
---
---Strategy: instead of maintaining per-buffer autocmds that need constant
---re-registration when buffers are swapped in the tracked windows, we use
---a single global TextChanged/TextChangedI handler that checks at runtime
---whether the changed buffer belongs to one of our windows.  A separate
---BufWinEnter handler triggers an initial update when a brand-new buffer
---enters a window (since file loads don't fire TextChanged).
local function setup_autocmds()
  augroup = vim.api.nvim_create_augroup("JQRepl", { clear = true })

  -- ── edits in any buffer that currently occupies one of our windows ──
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local in_json = state.json_win and vim.api.nvim_win_is_valid(state.json_win)
        and vim.api.nvim_win_get_buf(state.json_win) == buf
      local in_jq = state.jq_win and vim.api.nvim_win_is_valid(state.jq_win)
        and vim.api.nvim_win_get_buf(state.jq_win) == buf
      if in_json or in_jq then
        debounced_update()
      end
    end,
  })

  -- ── new buffer enters the JSON source or JQ expression window ──
  -- This covers :edit, :bnext, :tabnext back, etc. where TextChanged
  -- won't fire for the initial file load.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    callback = function()
      for _, spec in ipairs {
        { win = "json_win",    cache = "json_buf" },
        { win = "jq_win",      cache = "jq_buf" },
      } do
        local wid = state[spec.win]
        if wid and vim.api.nvim_win_is_valid(wid) then
          local buf = vim.api.nvim_win_get_buf(wid)
          if buf ~= state[spec.cache] then
            state[spec.cache] = buf
            debounced_update()
          end
        end
      end
    end,
  })

  -- ── tear down the whole REPL when any of our windows is closed ──
  local win_ids = { state.jq_win, state.json_win, state.preview_win }
  for _, wid in ipairs(win_ids) do
    if wid and vim.api.nvim_win_is_valid(wid) then
      vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        pattern = tostring(wid),
        callback = function()
          vim.schedule(function()
            M.close()
          end)
        end,
      })
    end
  end
end

---Start the JQ REPL.
---
---Calling this when a REPL is already active first tears it down.
---
---@param opts? { file?: string, debounce_ms?: integer }
function M.start(opts)
  opts = opts or {}

  if not has_jq() then
    vim.notify("JQRepl: jq is not installed", vim.log.levels.ERROR)
    return
  end

  -- Close any previous session.
  M.close()

  -- Store config before building the layout.
  state.debounce_ms = opts.debounce_ms or default_debounce_ms

  -- Determine the JSON source and open it in a fresh tab.
  if opts.file and opts.file ~= "" then
    vim.cmd("tabedit " .. vim.fn.fnameescape(opts.file))
  elseif vim.bo[vim.api.nvim_get_current_buf()].filetype == "json" then
    vim.cmd("tab split")
  else
    vim.cmd("tabnew")
    state.json_buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), state.json_buf)
    vim.bo[state.json_buf].filetype = "json"
  end

  state.json_buf = vim.api.nvim_get_current_buf()
  state.json_win = vim.api.nvim_get_current_win()

  create_layout()
  setup_autocmds()

  -- Initial preview.
  debounced_update()

  vim.notify("JQRepl started. Close any REPL window to quit, or use :JQreplclose", vim.log.levels.INFO)
end

---Tear down the REPL: close windows, wipe scratch buffers, cancel debounce.
function M.close()
  if state.closing then return end
  state.closing = true

  cancel_debounce()

  -- Remove all REPL autocmds so no stale handlers survive.
  if augroup then
    pcall(vim.api.nvim_clear_autocmds, { group = augroup })
  end

  -- Close all REPL windows, including the JSON source window (the last
  -- remaining window in the tab), which automatically tears down the
  -- containing tabpage.  With bufhidden=wipe the preview buffer is
  -- auto-wiped; the jq buffer is bufhidden=hide so it survives as hidden
  -- — we delete it explicitly below to free its name for the next session.
  local wins = { state.preview_win, state.jq_win, state.json_win }
  for _, win in ipairs(wins) do
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- Delete scratch buffers that would otherwise keep their names reserved.
  local old_jq = state.jq_buf
  if old_jq and vim.api.nvim_buf_is_valid(old_jq) then
    pcall(vim.api.nvim_buf_delete, old_jq, { force = true })
  end
  local old_preview = state.preview_buf
  if old_preview and vim.api.nvim_buf_is_valid(old_preview) then
    pcall(vim.api.nvim_buf_delete, old_preview, { force = true })
  end

  -- Guards are reset.
  state.jq_buf = nil
  state.jq_win = nil
  state.json_buf = nil
  state.json_win = nil
  state.preview_buf = nil
  state.preview_win = nil

  state.closing = false
end

---Return whether a REPL session is currently active.
---Resolves buffers from the tracked windows at runtime so we never
---return a false positive from stale cached state.
---@return boolean
function M.is_active()
  return win_current_buf("jq_win") ~= nil
    and win_current_buf("preview_win") ~= nil
end

vim.api.nvim_create_user_command("JQrepl", function(info)
  if info.args and info.args ~= "" then
    M.start({ file = info.args })
  else
    M.start({})
  end
end, {
  nargs = "?",
  complete = "file",
  desc = "Start JQ REPL (optional: path to JSON file)",
})

vim.api.nvim_create_user_command("JQreplClose", function()
  M.close()
end, {
  desc = "Close the JQ REPL session",
})

return M
