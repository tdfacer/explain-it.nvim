-- Example setup for AI Context Builder with explain-it.nvim

-- First, ensure both morph.nvim and explain-it.nvim are in your runtime path
-- This example assumes they are in the parent directory
local current_dir = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h")
local parent_dir = vim.fn.fnamemodify(current_dir, ":h:h")
vim.opt.rtp:prepend(parent_dir)
vim.opt.rtp:prepend(vim.fn.fnamemodify(parent_dir, ":h")) -- For morph.nvim

-- Setup explain-it with Context Builder enabled
require("explain-it").setup {
  -- Existing explain-it configuration
  debug = true,
  max_notification_width = 200,
  output_directory = "/tmp/explain_it_output",

  -- Enable the Context Builder feature
  context_builder = {
    enabled = true, -- Must be true to use Context Builder

    -- Configure AI providers
    default_provider = "aichat", -- or "openai", "llm", etc.
    providers = {
      -- OpenAI (uses existing explain-it OpenAI integration)
      openai = {
        -- Inherits from main explain-it config
      },

      -- AIChat CLI tool
      aichat = {
        command = "aichat",
        args = { "--no-stream" },
      },

      -- Simon Willison's llm tool
      llm = {
        command = "llm",
        args = { "prompt", "-m", "gpt-4" },
      },

      -- Ollama for local models
      ollama = {
        command = "ollama",
        args = { "run", "codellama" },
        streaming = true,
      },

      -- Custom CLI tool example
      my_ai = {
        command = "my-ai-cli",
        args = { "--format", "json" },
        format_input = function(context, instruction)
          -- Custom formatting for your CLI tool
          return vim.fn.json_encode {
            context = context,
            prompt = instruction,
          }
        end,
        parse_response = function(output)
          -- Parse JSON response
          local ok, decoded = pcall(vim.fn.json_decode, output)
          if ok and decoded.response then return decoded.response end
          return output
        end,
      },
    },

    -- Session management
    session_dir = vim.fn.stdpath("data") .. "/explain-it/sessions",
    auto_save = true,
    auto_save_interval = 300, -- Save every 5 minutes

    -- UI configuration
    window_config = {
      split = "vertical", -- or "horizontal"
      width = 0.4, -- 40% of screen width
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

-- Create keybindings
local opts = { noremap = true, silent = true }

-- Open Context Builder
vim.keymap.set("n", "<leader>ac", function() require("explain-it").open_context_builder() end, opts)

-- Quick add current file to context
vim.keymap.set("n", "<leader>af", function()
  -- This would be implemented as part of the full feature
  vim.notify("Add file to context: Not implemented yet", vim.log.levels.INFO)
end, opts)

-- Quick add visual selection to context
vim.keymap.set("v", "<leader>as", function()
  -- This would be implemented as part of the full feature
  vim.notify("Add snippet to context: Not implemented yet", vim.log.levels.INFO)
end, opts)

-- Example: Open Context Builder with a template
vim.keymap.set(
  "n",
  "<leader>ar",
  function() require("explain-it").open_context_builder { template = "code_review" } end,
  opts
)

-- Commands for session management (would be implemented)
vim.api.nvim_create_user_command("ExplainItContext", function(args)
  local opts = {}
  if args.args ~= "" then
    -- Parse template=name format
    local template = args.args:match("template=(%w+)")
    if template then opts.template = template end
  end
  require("explain-it").open_context_builder(opts)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ExplainItSession", function(args)
  local parts = vim.split(args.args, " ")
  local cmd = parts[1]
  local name = parts[2]

  if cmd == "save" and name then
    vim.notify("Save session: " .. name .. " (Not implemented yet)", vim.log.levels.INFO)
  elseif cmd == "load" and name then
    vim.notify("Load session: " .. name .. " (Not implemented yet)", vim.log.levels.INFO)
  elseif cmd == "list" then
    vim.notify("List sessions (Not implemented yet)", vim.log.levels.INFO)
  else
    vim.notify("Usage: ExplainItSession <save|load|list> [name]", vim.log.levels.ERROR)
  end
end, {
  nargs = "+",
  complete = function(arg_lead, cmd_line, cursor_pos)
    local parts = vim.split(cmd_line, " ")
    if #parts == 2 then
      return { "save", "load", "list" }
    elseif #parts == 3 and (parts[2] == "load" or parts[2] == "save") then
      -- TODO: Return list of existing sessions
      return {}
    end
    return {}
  end,
})

print("AI Context Builder example loaded!")
print("Commands:")
print("  <leader>ac - Open Context Builder")
print("  <leader>af - Add current file to context")
print("  <leader>as - Add visual selection to context")
print("  <leader>ar - Open Context Builder with code review template")
print("  :ExplainItContext [template=name] - Open with optional template")
print("  :ExplainItSession save|load|list [name] - Manage sessions")
