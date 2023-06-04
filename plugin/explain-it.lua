-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.ExplainItLoaded then
  return
end

_G.ExplainItLoaded = true

vim.api.nvim_create_user_command("ExplainIt", function()
  require("explain-it").toggle()
end, {})

local system = require "explain-it.system"
system.make_system_call(string.format("mkdir -p %s", _G.ExplainIt.config.output_directory))

local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>z", require("explain-it").explain_it, opts)
vim.keymap.set("v", "<space>z", require("explain-it").explain_it, opts)
vim.keymap.set("n", "<space>Z", function()
  require("explain-it").explain_it { custom_prompt = true }
end, opts)
-- vim.keymap.set("v", "<space>Z", function() require"explain-it".explain_it_visual({custom_prompt = true}) end, opts)
vim.keymap.set("v", "<space>Z", function()
  require("explain-it").explain_it { custom_prompt = true, is_visual = true }
end, opts)
vim.keymap.set("n", "<space>x", function()
  require("explain-it").explain_it { custom_prompt = false, api_type = "chat" }
end, opts)
vim.keymap.set("v", "<space>x", function()
  require("explain-it").explain_it { custom_prompt = false, api_type = "chat", is_visual = true }
end, opts)
vim.keymap.set("n", "<space>X", function()
  require("explain-it").explain_it { custom_prompt = true, api_type = "chat" }
end, opts)
vim.keymap.set("v", "<space>X", function()
  require("explain-it").explain_it { custom_prompt = true, api_type = "chat", is_visual = true }
end, opts)
