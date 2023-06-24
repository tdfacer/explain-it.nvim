local buff = require "explain-it.util.buffer"
local escape = require "explain-it.util.escape"
local chat_gpt = require "explain-it.services.chat-gpt"
local D = require "explain-it.util.debug"
local notify = require "notify"
local ExplainIt = {}

--- Sets up plugin with user-provided options
---@param opts any
function ExplainIt.setup(opts)
  vim.print("~/code/ExplainIt.setup")
  opts.debug = opts.debug or false
  opts.max_notification_width = opts.max_notification_width or 120
  opts.max_retries = opts.max_retries or 3
  opts.output_directory = opts.output_directory or "/tmp/chat_output"
  opts.split_responses = opts.split_responses or "false"
  opts.token_limit = opts.token_limit or 1000
  opts.append_current_buffer = opts.append_current_buffer or false
  opts.output_to_buffer = opts.output_to_buffer or false
  opts.api_type = opts.api_type or "completion"
  opts.is_visual = opts.is_visual or false
  opts.default_prompt = opts.default_prompt or "Please answer the provided questionz:"
  _G.ExplainIt.config = require("explain-it.config").setup(opts)
end

--- Core function for preparing requests to external services. Based on input,
--- will either pull the contents of the full buffer into a variable or just the
--- visually selected text, then call call_chat_gpt with it.
---@param opts any
function ExplainIt.explain_it(opts)
  if not opts then
    opts = {}
  end

  opts.debug = opts.debug or _G.ExplainIt.config.debug or false
  opts.max_notification_width = opts.max_notification_width or _G.ExplainIt.config.max_notification_width or 120
  opts.max_retries = opts.max_retries or _G.ExplainIt.config.max_retries or 3
  opts.output_directory = opts.output_directory or _G.ExplainIt.config.output_directory or "/tmp/chat_output"
  opts.split_responses = opts.split_responses or _G.ExplainIt.config.split_responses or "false"
  opts.token_limit = opts.token_limit or _G.ExplainIt.config.token_limit or 1000
  opts.append_current_buffer = opts.append_current_buffer or _G.ExplainIt.config.append_current_buffer or false
  opts.output_to_buffer = opts.output_to_buffer or _G.ExplainIt.config.output_to_buffer or false
  opts.api_type = opts.api_type or _G.ExplainIt.config.api_type or "completion"
  opts.is_visual = opts.is_visual or _G.ExplainIt.config.is_visual or false
  opts.default_prompt = opts.default_prompt or _G.ExplainIt.config.default_prompt or "Please answer the provided question:"

  local text = ""
  if opts.is_visual then
    text = buff.get_visual_selection()
  else
    text = buff.get_buffer_lines()
  end
  local escaped = escape.get_escaped_string(text)
  local joined = string.gsub(escaped, "\n", "\\n")
  opts.text = joined
  if opts.custom_prompt then
    vim.ui.input({ prompt = "Enter the custom prompt: " }, function(custom_prompt)
      D.log("init", "custom_prompt: %s", custom_prompt)
      opts.custom_prompt = escape.get_escaped_string(custom_prompt)
      ExplainIt.call_chat_gpt(opts)
    end)
  else
    ExplainIt.call_chat_gpt(opts)
  end
end

--- Takes prepared input text and calls either the chat or the completion api on the chat-gpt module
---@param opts any
function ExplainIt.call_chat_gpt(opts)
  D.log("init.call_chat_gpt", "opts: %s", vim.inspect(opts))
  local custom_prompt = opts and opts.custom_prompt or nil
  local response = ""
  if opts.api_type == "completion" then
    D.log("ExplainIt.call_chat_gpt", "using completion")
    response = chat_gpt.call_gpt(opts.text, custom_prompt, "command")
  else
    D.log("ExplainIt.call_chat_gpt", "using chat")
    response = chat_gpt.call_gpt(opts.text, custom_prompt, "chat_command")
  end

  if opts.append_current_buffer then
    D.log("init", "writing response to current buffer")
    buff.append_buffer_lines(0, response)
    -- local lines = {}
    -- for line in response:gmatch("[^\n]+") do
    --   table.insert(lines, line)
    -- end
    -- -- local res, _ = string.gsub(response, "\n", "\\n")
    -- vim.api.nvim_buf_set_lines(0, -1, -1, false, lines)
    -- string.gsub(response, "\n", "\\n")
  end
  if opts.output_to_buffer then
    D.log("explain-it.init", "output to buffer")
    local output_buffer = vim.api.nvim_create_buf(true, false)
    buff.append_buffer_lines(output_buffer, table.concat({ custom_prompt, response }, "\n\n"))
  end
  --   local lines = {}
  --   for line in response:gmatch("[^\n]+") do
  --     table.insert(lines, line)
  --   end
  --   vim.api.nvim_buf_set_lines(output_buffer, -1, -1, false, lines)
  -- end
  notify(response)
end

_G.ExplainIt = ExplainIt

return _G.ExplainIt
