local buff = require "explain-it.util.buffer"
local response_handler = require "explain-it.handlers.response"
local escape = require "explain-it.util.escape"
local chat_gpt = require "explain-it.services.chat-gpt"
local D = require "explain-it.util.debug"
local ExplainIt = {}

--- Sets up plugin with user-provided options
---@param opts any
function ExplainIt.setup(opts)
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

  opts.api_type = opts.api_type or "completion"
  opts.is_visual = opts.is_visual or false
  opts.custom_prompt = opts.custom_prompt or false
  opts.output_to_buffer = opts and opts.output_to_buffer or false

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
      opts.custom_prompt = custom_prompt
      ExplainIt.call_chat_gpt(opts)
    end)
  else
    ExplainIt.call_chat_gpt(opts)
  end
end

--- Takes prepared input text and calls either the chat or the completion api on the chat-gpt module
---@param opts any
function ExplainIt.call_chat_gpt(opts)
  local custom_prompt = opts and opts.custom_prompt or nil
  D.log("ExplainIt.call_chat_gpt", "opts: %s", vim.inspect(opts))
  local ai_response = {}
  if opts.api_type == "completion" then
    D.log("ExplainIt.call_chat_gpt", "using completion")
    ai_response = chat_gpt.call_gpt(opts.text, custom_prompt, "command")
  else
    D.log("ExplainIt.call_chat_gpt", "using chat")
    ai_response = chat_gpt.call_gpt(opts.text, custom_prompt, "chat_command")
  end
  response_handler.notify_response(ai_response)
  if opts.output_to_buffer then
    response_handler.append_buffer_response(ai_response)
  end
end

--- Opens the interactive AI Context Builder interface
---@param opts table|nil Optional configuration for the context builder
function ExplainIt.open_context_builder(opts)
  if not _G.ExplainIt.config.context_builder.enabled then
    vim.notify("Context Builder is not enabled. Set context_builder.enabled = true in setup()", vim.log.levels.WARN)
    return
  end

  local ContextBuilder = require("explain-it.context-builder")
  ContextBuilder.open(opts)
end

--- Add current file to the active Context Builder
function ExplainIt.add_current_file_to_context()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file open in current buffer", vim.log.levels.WARN)
    return
  end

  -- Make sure we have a real file
  if not vim.fn.filereadable(filepath) then
    vim.notify("Current buffer is not a saved file: " .. filepath, vim.log.levels.WARN)
    return
  end

  local ContextBuilder = require("explain-it.context-builder")
  ContextBuilder.add_file(filepath)
end

--- Add visual selection to the active Context Builder
function ExplainIt.add_selection_to_context()
  local buf = require("explain-it.util.buffer")
  local selection = buf.get_visual_selection()

  if not selection or selection == "" then
    vim.notify("No selection found", vim.log.levels.WARN)
    return
  end

  local filepath = vim.fn.expand("%:p")
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local ContextBuilder = require("explain-it.context-builder")
  ContextBuilder.add_snippet(filepath, start_pos[2], end_pos[2], selection)
end

_G.ExplainIt = ExplainIt

return _G.ExplainIt
