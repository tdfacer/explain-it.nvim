local M = {}

--- Plugin default config values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
  append_current_buffer = false,
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = false,
  max_notification_width = 200,
  max_retries = 3,
  -- Which API provider to send requests to: "openai" or "anthropic".
  provider = "openai",
  openai_chat_model = "gpt-5",
  openai_completion_model = "text-davinci-003",
  -- Name of the env var holding the OpenAI API key.
  openai_api_key_env = "CHAT_GPT_API_KEY",
  -- Model used when `provider = "anthropic"`. Supported recent models include:
  -- claude-opus-4-8, claude-opus-4-7, claude-sonnet-4-6, claude-opus-4-6, claude-haiku-4-5
  anthropic_chat_model = "claude-opus-4-8",
  -- Name of the env var holding the Anthropic API key.
  anthropic_api_key_env = "ANTHROPIC_API_KEY",
  output_directory = "/tmp/explain_it_output",
  split_responses = true,
  token_limit = 2000,
  default_prompts = {
    ["markdown"] = "Answer this question:",
    ["txt"] = "Explain this block of text:",
    ["lua"] = "What does this code do?",
    ["zsh"] = "Answer this question:",
  },
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
