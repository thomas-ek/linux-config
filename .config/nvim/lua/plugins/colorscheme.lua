return {
  "EdenEast/nightfox.nvim",
  config = function()
    require("nightfox").setup({
      options = {
        styles = {
          comments = "bold",
          keywords = "italic",
          types = "italic,bold",
        },
      },
    })
  end,
}
