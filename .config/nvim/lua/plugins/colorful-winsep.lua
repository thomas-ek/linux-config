return {
  {
    "nvim-zh/colorful-winsep.nvim",
    -- The active window's frame is drawn by config/active-frame.lua
    enabled = false,
    event = { "WinNew", "WinEnter" },
    config = true,
    opts = {
      border = "bold",
      highlight = { fg = "#E8833A", bg = "NONE" },
    },
  },
}
