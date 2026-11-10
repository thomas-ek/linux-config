-- Draws a frame around the active window with non-focusable floats.
-- A side shared with another window is drawn over the window separator; a side on the screen
-- edge, where Neovim has no separator, is drawn over the window's outermost row or column.

local M = {}

local color = "#0087FF" -- tmux colour33, the active pane border
local dimmed_color = "#444444" -- tmux colour238, the inactive pane border
local focused = true
local ns_group = vim.api.nvim_create_augroup("active_window_frame", { clear = true })
local frame_wins = {}

local incline_focused_hl

local function set_highlight()
  vim.api.nvim_set_hl(0, "ActiveFrame", { fg = focused and color or dimmed_color, bg = "NONE" })
end

-- The focused window's file name label (incline) takes the unfocused label's look while
-- Neovim itself is unfocused
local function set_incline_highlight()
  if focused then
    if incline_focused_hl then
      vim.api.nvim_set_hl(0, "InclineNormal", incline_focused_hl)
      incline_focused_hl = nil
    end
  elseif not incline_focused_hl then
    incline_focused_hl = vim.api.nvim_get_hl(0, { name = "InclineNormal", link = false })
    vim.api.nvim_set_hl(0, "InclineNormal", vim.api.nvim_get_hl(0, { name = "InclineNormalNC", link = false }))
  end
end

local function clear()
  for _, win in ipairs(frame_wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  frame_wins = {}
end

local function open(row, col, width, height, lines)
  if width < 1 or height < 1 then
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    focusable = false,
    zindex = 1,
    noautocmd = true,
  })
  vim.wo[win].winhighlight = "Normal:ActiveFrame,NormalNC:ActiveFrame"
  vim.wo[win].winblend = 0
  table.insert(frame_wins, win)
end

local function is_float(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function normal_window_count()
  local count = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(win) then
      count = count + 1
    end
  end
  return count
end

local function draw()
  local win = vim.api.nvim_get_current_win()
  if is_float(win) then
    return
  end
  clear()
  if normal_window_count() < 2 then
    return
  end

  -- true when the side has no neighbour window, i.e. it lies on the screen edge
  local edge = vim.api.nvim_win_call(win, function()
    local current = vim.fn.winnr()
    return {
      top = vim.fn.winnr("k") == current,
      bottom = vim.fn.winnr("j") == current,
      left = vim.fn.winnr("h") == current,
      right = vim.fn.winnr("l") == current,
    }
  end)

  local pos = vim.api.nvim_win_get_position(win)
  local top, left = pos[1], pos[2]
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local bottom, right = top + height - 1, left + width - 1

  -- The separator of a neighbour window sits on the row or column just outside the window
  local frame_top = edge.top and top or top - 1
  local frame_bottom = edge.bottom and bottom or bottom + 1
  local frame_left = edge.left and left or left - 1
  local frame_right = edge.right and right or right + 1
  local frame_width = frame_right - frame_left + 1

  open(frame_top, frame_left, frame_width, 1, { "┏" .. string.rep("━", frame_width - 2) .. "┓" })
  open(frame_bottom, frame_left, frame_width, 1, { "┗" .. string.rep("━", frame_width - 2) .. "┛" })

  local rows = frame_bottom - frame_top - 1
  if rows > 0 then
    local column = {}
    for i = 1, rows do
      column[i] = "┃"
    end
    open(frame_top + 1, frame_left, 1, rows, column)
    open(frame_top + 1, frame_right, 1, rows, column)
  end
end

function M.setup()
  set_highlight()
  vim.api.nvim_create_autocmd("ColorScheme", { group = ns_group, callback = set_highlight })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinResized", "VimResized", "TabEnter", "WinClosed" }, {
    group = ns_group,
    callback = function(event)
      -- closing the frame's own floats must not trigger a redraw
      if event.event == "WinClosed" and vim.tbl_contains(frame_wins, tonumber(event.match)) then
        return
      end
      vim.schedule(draw)
    end,
  })
  vim.api.nvim_create_autocmd("TabLeave", { group = ns_group, callback = clear })
  -- tmux reports pane focus changes to Neovim when its focus-events option is on
  vim.api.nvim_create_autocmd({ "FocusGained", "FocusLost" }, {
    group = ns_group,
    callback = function(event)
      focused = event.event == "FocusGained"
      set_highlight()
      set_incline_highlight()
      vim.cmd.redraw()
    end,
  })
  vim.schedule(draw)
end

return M
