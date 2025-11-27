-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.keymap.set("n", "<Leader>e", function()
  vim.diagnostic.open_float({
    focusable = true,
    scope = "line",
    close_events = {}, -- Keeps the diagnostic open until you close it manually
  })
end, { desc = "Show persistent diagnostic" })
function OpenCodeCompanionAction()
  -- Assuming CodeCompanion is a function or a command that opens the assistant
  -- Replace this with the actual command or function to open CodeCompanion
  -- For demonstration, let's assume it's a command named 'CodeCompanion'
  vim.cmd("CodeCompanionAction")
end
function OpenCodeCompanionChat()
  -- Assuming CodeCompanion is a function or a command that opens the assistant
  -- Replace this with the actual command or function to open CodeCompanion
  -- For demonstration, let's assume it's a command named 'CodeCompanion'
  vim.cmd("CodeCompanionChat")
end

-- Create a custom command 'cc' that calls the OpenCodeCompanion function
vim.api.nvim_create_user_command("CCA", "lua OpenCodeCompanionAction()", {})
vim.api.nvim_create_user_command("CCC", "lua OpenCodeCompanionChat()", {})
vim.api.nvim_create_user_command("Y", function()
  vim.cmd("Yazi")
end, { desc = "Open Yazi (alias)" })

-- Customized theme
vim.cmd("colorscheme dayfox")
require("config.cursor")
