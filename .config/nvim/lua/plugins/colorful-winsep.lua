return {
  {
    "nvim-zh/colorful-winsep.nvim",
    event = { "WinNew", "WinEnter" },
    config = true,
    opts = {
      hi = { fg = "#FAB387", bg = "NONE" }, -- separator colour
      symbols = { "━", "┃", "┏", "┓", "┗", "┛" }, -- heavy box-drawing set
    },
  },
}
