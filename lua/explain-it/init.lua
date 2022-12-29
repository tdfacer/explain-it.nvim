local buff = require "explain-it.util.buffer"
local escape = require "explain-it.util.escape"
local chat_gpt = require "explain-it.services.chat-gpt"
local D = require "explain-it.util.debug"
local notify = require "notify"
local ExplainIt = {}

---Sets up plugin with user-provided options
---@param opts any
function ExplainIt.setup(opts)
  _G.ExplainIt.config = require("explain-it.config").setup(opts)
end

---Core function for preparing requests to external services. Based on input,
---will either pull the contents of the full buffer into a variable or just the
---visually selected text, then call call_chat_gpt with it.
---@param opts any
function ExplainIt.explain_it(opts)
  if not opts then
    opts = {}
  end

  opts.api_type = opts.api_type or "completion"
  opts.is_visual = opts.is_visual or false
  opts.custom_prompt = opts.custom_prompt or false

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
      opts.custom_prompt = custom_prompt
      ExplainIt.call_chat_gpt(opts)
    end)
  else
    ExplainIt.call_chat_gpt(opts)
  end
end

---Takes prepared input text and calls either the chat or the completion api on the chat-gpt module
---@param opts any
function ExplainIt.call_chat_gpt(opts)
  local custom_prompt = opts and opts.custom_prompt or nil
  local response = ""
  if opts.api_type == "completion" then
    D.log("ExplainIt.call_chat_gpt", "using completion")
    response = chat_gpt.call_gpt(opts.text, custom_prompt, "command")
  else
    D.log("ExplainIt.call_chat_gpt", "using chat")
    response = chat_gpt.call_gpt(opts.text, custom_prompt, "chat_command")
  end
  notify(response)
end

_G.ExplainIt = ExplainIt

return _G.ExplainIt
