local M = {}

--- Plugin default config values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
  append_current_buffer = false,
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = false,
  max_notification_width = 200,
  max_retries = 3,
  output_directory = "/tmp/explain_it_output",
  split_responses = true,
  token_limit = 2000,
  default_prompts = {
    ["markdown"] = "Explain this block of text:",
    ["txt"] = "Explain this block of text:",
    ["lua"] = "What does this code do?",
  }
}

---@param options table Module config table. See |M.options|.
---
---@usage `require("explain-it").setup()` (add `{}` with your |M.options| table)
function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("keep", options, M.options)

  local system = require "explain-it.system"
  system.make_system_call(string.format("mkdir -p %s", M.options.output_directory))

  return M.options
end

return M
