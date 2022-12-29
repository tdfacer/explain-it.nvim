local ExplainIt = {}

--- Plugin default config values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
ExplainIt.options = {
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = true,
  max_notification_width = 20,
  max_retries = 3,
}

---@param options table Module config table. See |ExplainIt.options|.
---
---@usage `require("explain-it").setup()` (add `{}` with your |ExplainIt.options| table)
function ExplainIt.setup(options)
  options = options or {}

  ExplainIt.options = vim.tbl_deep_extend("keep", options, ExplainIt.options)

  return ExplainIt.options
end

return ExplainIt
