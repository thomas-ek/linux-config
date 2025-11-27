-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Keymaps Config for LazyVim (with vim-visual-multi tweaks)

-- First, remove LazyVim's default window resizing bindings
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Up>")

-- Optional: If you want to remove the horizontal resize too (just in case)
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

-- Setup vim-visual-multi bindings (works if you have vim-visual-multi installed)
-- These assume you want multi-cursor navigation similar to VSCode

-- Add cursor down
vim.keymap.set("n", "<C-Down>", "<Plug>(VM-Add-Cursor-Down)", { noremap = true, silent = true })
vim.keymap.set("i", "<C-Down>", "<Esc><Plug>(VM-Add-Cursor-Down)", { noremap = true, silent = true })
vim.keymap.set("v", "<C-Down>", "<Esc><Plug>(VM-Add-Cursor-Down)", { noremap = true, silent = true })

-- Add cursor up
vim.keymap.set("n", "<C-Up>", "<Plug>(VM-Add-Cursor-Up)", { noremap = true, silent = true })
vim.keymap.set("i", "<C-Up>", "<Esc><Plug>(VM-Add-Cursor-Up)", { noremap = true, silent = true })
vim.keymap.set("v", "<C-Up>", "<Esc><Plug>(VM-Add-Cursor-Up)", { noremap = true, silent = true })

-- 📝 Example section for your own personal keymaps
-- (Optional) Add your other personal keymaps here
vim.keymap.set("n", "<Leader>e", function()
  vim.diagnostic.open_float()
end, { desc = "Show persistent diagnostic" })
vim.keymap.set("n", "<leader>CC", ":CodeCompanionChat<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>CA", ":CodeCompanionAction<CR>", { noremap = true, silent = true })
-- Add more keymaps below as needed
