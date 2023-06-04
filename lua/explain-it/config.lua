local M = {}

--- Plugin default config values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = true,
  max_notification_width = 20,
  max_retries = 3,
  output_directory = "/tmp/chat_output",
  token_limit = 2000,
}

---@param options table Module config table. See |M.options|.
---
---@usage `require("explain-it").setup()` (add `{}` with your |M.options| table)
function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("keep", options, M.options)

  return M.options
end

return M
