-- lua/config/cursor.lua
-- Visibility boosters for Dayfox – cursor, line & column tweaks
-- Updated: keep full‑line highlight when using `cursorlineopt = number` + sync colour for CursorColumn

---------------------------------------------------------------------
-- 0. 24‑bit colour safety net
---------------------------------------------------------------------
if vim.fn.has("termguicolors") == 1 then
  vim.opt.termguicolors = true
end

---------------------------------------------------------------------
-- 1. Highlight the whole line **and** its number **and** its column
---------------------------------------------------------------------
vim.opt.cursorline = true -- enable line highlight
vim.opt.cursorlineopt = "line,number" -- highlight both line + number
vim.opt.cursorcolumn = true -- enable column highlight

local line_bg = "#E4DAEC" -- pale plum‑gray that works on Dayfox

vim.api.nvim_set_hl(0, "CursorLine", { bg = line_bg })
vim.api.nvim_set_hl(0, "CursorColumn", { bg = line_bg })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#EBCB8B", bold = true }) -- gold & bold number

---------------------------------------------------------------------
-- 2. Cursor shapes & colours ----------------------------------------------
--   • Normal → big gold block (or yellow on 256‑colour TTY)
--   • Insert → slim cyan bar
---------------------------------------------------------------------
vim.api.nvim_set_hl(0, "Cursor", {
  bg = "#FFD400",
  fg = "#1E1E2E", -- GUI (true‑colour)
  ctermbg = 226,
  ctermfg = 16, -- 256‑colour fallback
})

vim.api.nvim_set_hl(0, "CursorInsert", {
  bg = "#00D3D0",
  fg = "#1E1E2E",
  ctermbg = 14,
  ctermfg = 16,
})

vim.opt.guicursor = table.concat({
  "n-v-c:block-Cursor-blinkon0", -- Normal/Visual/Command → block
  "i:ver25-CursorInsert", -- Insert → bar
  "r-cr:hor20", -- Replace/Prompt → underline
  "o:hor50", -- Operator‑pending
}, ",")

---------------------------------------------------------------------
-- 3. Extra highlights (kept from your previous setup) ----------------------
---------------------------------------------------------------------
vim.api.nvim_set_hl(0, "Visual", { bg = "#D7CCE6", fg = "#1E1E2E" })
vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = "#D7CCE6", fg = "#1E1E2E", bold = true })
vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = "#6CAEDA", bold = true })
vim.api.nvim_set_hl(0, "Search", { bg = "#FFE8A3", fg = "#1E1E2E", bold = true })
vim.api.nvim_set_hl(0, "IncSearch", { bg = "#F2B5A8", fg = "#1E1E2E", bold = true })
vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#ECE7F2" })
vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#ECE7F2" })
vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#ECE7F2" })

---------------------------------------------------------------------
-- 4. Toggle the line highlight quickly with <leader>tl --------------------
---------------------------------------------------------------------
vim.keymap.set("n", "<leader>tl", function()
  vim.wo.cursorline = not vim.wo.cursorline
end, { desc = "Toggle CursorLine" })

---------------------------------------------------------------------
-- 5. Optional Neovide cursor effects --------------------------------------
---------------------------------------------------------------------
if vim.g.neovide then
  vim.g.neovide_cursor_vfx_mode = "railgun"
end
