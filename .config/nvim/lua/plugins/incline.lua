return {
  "b0o/incline.nvim",
  config = function()
    -- InclineNormal (focused window label) is set in config/cursor.lua
    require("incline").setup()
  end,
  -- Optional: Lazy load Incline
  event = "VeryLazy",
}
