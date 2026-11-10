-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Draw the cursor line and column only in the active window
local active_cursor = vim.api.nvim_create_augroup("active_window_cursor", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = active_cursor,
  callback = function()
    vim.wo.cursorline = true
    vim.wo.cursorcolumn = true
  end,
})
vim.api.nvim_create_autocmd("WinLeave", {
  group = active_cursor,
  callback = function()
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
  end,
})
