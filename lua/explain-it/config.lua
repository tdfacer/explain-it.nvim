local M = {}

--- Plugin default config values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = true,
  max_notification_width = 20,
  max_retries = 3,
  output_directory = "/tmp/chat_output",
  split_responses = false,
  token_limit = 2000,
}

---@param options table Module config table. See |M.options|.
---
---@usage `require("explain-it").setup()` (add `{}` with your |M.options| table)
function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("keep", options, M.options)

  local system = require "explain-it.system"
  system.make_system_call(string.format("mkdir -p %s", M.options.output_directory))

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

  return M.options
end

return M
