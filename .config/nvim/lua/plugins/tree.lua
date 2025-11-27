return {
  ---------------------------------------------------------------------------
  -- 1.  Disable Neo-tree and its default keymaps
  ---------------------------------------------------------------------------
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- wipe the <leader>e… bindings that pointed to Neo-tree
  {
    "LazyVim/LazyVim",
    keys = {
      { "<leader>e", false },
      { "<leader>E", false },
      { "<leader>fe", false },
      { "<leader>fE", false },
    },
  },

  ---------------------------------------------------------------------------
  -- 2.  Pull in yazi.nvim and hook it to the same keys
  ---------------------------------------------------------------------------
  {
    "mikavilpas/yazi.nvim",
    cmd = "Yazi", -- lazy-load on first :Yazi
    opts = {
      -- set this to true if you want Yazi to open automatically
      -- whenever you :edit a directory
      open_for_directories = false,
      floating_window_scaling_factor = 0.95,
    },
    -- reuse the old Neo-tree shortcuts
    keys = {
      { "<leader>E", "<cmd>Yazi cwd<CR>", desc = "Explorer (CWD)" },
      { "<C-Up>", "<cmd>Yazi toggle<CR>", desc = "Yazi • resume last" },
    },
    dependencies = { -- yazi.nvim pulls these lazily
      { "nvim-lua/plenary.nvim", lazy = true },
    },
  },

  ---------------------------------------------------------------------------
  -- 3. (Optional) turn off devicons if nothing else uses them
  ---------------------------------------------------------------------------
  { "nvim-tree/nvim-web-devicons", enabled = false },
}
