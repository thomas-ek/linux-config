return {
  -- LSP plugin configuration for Python (Pyright)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {}, -- Enable Pyright for Python
      },
      -- Ensure LSP works with format-on-save
      autoformat = true,
    },
  },
}
