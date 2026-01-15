local M = {}

--- Plugin default config values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
  append_current_buffer = false,
  -- Prints useful logs about what event are triggered, and reasons actions are executed.
  debug = false,
  max_notification_width = 200,
  max_retries = 3,
  -- Base API URL for OpenAI-compatible endpoints
  model_base_api = "https://api.openai.com/v1",
  openai_chat_model = "gpt-4.1-mini",
  -- Legacy: completions API is deprecated, prefer chat API
  openai_completion_model = "gpt-4.1-mini",
  output_directory = "/tmp/explain_it_output",
  split_responses = true,
  token_limit = 2000,
  default_prompts = {
    ["markdown"] = "Answer this question:",
    ["txt"] = "Explain this block of text:",
    ["lua"] = "What does this code do?",
    ["zsh"] = "Answer this question:",
  },

  -- Context Builder options
  context_builder = {
    enabled = false, -- Opt-in feature

    -- Provider configuration
    default_provider = "openai",
    providers = {
      openai = {
        -- Use existing OpenAI config
        -- Optionally override the model for Context Builder
        -- model = "gpt-4-turbo-preview",
      },
      aichat = {
        command = "aichat",
        args = { "--no-stream" },
      },
      llm = {
        command = "llm",
        args = { "prompt", "-s", "system.txt" },
      },
    },

    -- Session management
    session_dir = vim.fn.stdpath("data") .. "/explain-it/sessions",
    auto_save = true,
    auto_save_interval = 300, -- seconds

    -- UI preferences
    window_config = {
      split = "vertical",
      width = 0.4, -- 40% of screen
    },

    -- Templates
    templates_dir = vim.fn.stdpath("config") .. "/explain-it/templates",
    builtin_templates = {
      "code_review",
      "documentation",
      "refactoring",
      "debugging",
    },
  },
}

---@param options table Module config table. See |M.options|.
---
---@usage `require("explain-it").setup()` (add `{}` with your |M.options| table)
function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("keep", options, M.options)

  local system = require("explain-it.system")
  system.make_system_call(string.format("mkdir -p %s", M.options.output_directory))

  -- Create Context Builder directories if enabled
  if M.options.context_builder.enabled then
    system.make_system_call(string.format("mkdir -p %s", M.options.context_builder.session_dir))
    system.make_system_call(string.format("mkdir -p %s", M.options.context_builder.templates_dir))
  end

  return M.options
end

return M
