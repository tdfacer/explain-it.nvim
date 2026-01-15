local D = require("explain-it.util.debug")

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
  default_directory = nil,

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

    -- Directory add settings
    directory = {
      -- Directories to skip
      ignore_dirs = {
        ".git",
        "node_modules",
        ".svn",
        ".hg",
        "__pycache__",
        ".cache",
        "vendor",
        "dist",
        "build",
      },
      -- File patterns to ignore (Lua patterns)
      ignore_patterns = {
        "%.git/",
        "%.DS_Store$",
        "%.o$",
        "%.so$",
        "%.a$",
        "%.dylib$",
        "%.exe$",
        "%.dll$",
        "%.class$",
        "%.pyc$",
        "%.pyo$",
        "%.jpg$",
        "%.jpeg$",
        "%.png$",
        "%.gif$",
        "%.ico$",
        "%.pdf$",
        "%.zip$",
        "%.tar$",
        "%.gz$",
      },
      -- Whether to include hidden files (starting with .)
      include_hidden = false,
      -- Maximum number of files to add from a single directory operation
      max_files = 50,
      -- Maximum file size in bytes (skip files larger than this)
      max_file_size = 1024 * 1024, -- 1MB default
      -- Maximum recursion depth (nil = unlimited)
      max_depth = 10,
    },
  },
}

---@param options table Module config table. See |M.options|.
---
---@usage `require("explain-it").setup()` (add `{}` with your |M.options| table)
function M.setup(options)
  options = options or {}

  M.options = vim.tbl_deep_extend("keep", options, M.options)
  M.options.start_directory = vim.fn.expand("%:p:h")

  -- D.log_always("Explain-It config:", "%s", vim.inspect(M.options))
  -- if default_directory provided by user, use it; else set to standard data path
  -- if M.options.default_directory then
  --   M.options.output_directory = M.options.default_directory
  -- else
  --   local current_dir = vim.fn.expand("%:p:h")
  --   M.options.default_directory = current_dir
  -- end

  -- if not M.options.default_directory then
  --   M.options.default_directory = vim.fn.stdpath("data") .. "/explain-it"
  -- end

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
