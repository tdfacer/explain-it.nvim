local system = require "explain-it.system"
local string_util = require "explain-it.util.strings"

local D = require "explain-it.util.debug"

local M = {}

---@class AIResponse
---@field question string
---@field input string
---@field response string

---@alias completion_command string
local completion_command = [[
  curl ##MODEL_BASE_API##/v1/completions \
    2>/dev/null \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ##API_KEY##" \
    -d '{
      "model": "##MODEL##",
      "prompt": "##OPTIONAL_QUESTION##\n##ESCAPED_INPUT##",
      "max_tokens": 2000,
      "temperature": 0
    }'
]]

---@alias chat_command string
---https://api.x.ai/v1
-- local chat_command = [[
--   curl https://api.openai.com/v1/chat/completions \
--     2>/dev/null \
--     -H "Content-Type: application/json" \
--     -H "Authorization: Bearer ##API_KEY##" \
--     -d '{
--       "model": "##MODEL##",
--       "messages": [{"role": "user", "content": "##OPTIONAL_QUESTION##\n##ESCAPED_INPUT##"}],
--       "max_tokens": 2000,
--       "temperature": 0.2
--     }'
-- ]]

  -- curl https://api.x.ai/v1/chat/completions \
local chat_command = [[
  curl ##MODEL_BASE_API##/chat/completions \
    2>/dev/null \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ##API_KEY##" \
    -d '{
      "model": "##MODEL##",
      "messages": [{"role": "user", "content": "##OPTIONAL_QUESTION##\n##ESCAPED_INPUT##"}],
      "max_tokens": 2000,
      "temperature": 0.2
    }'
]]

---@enum commands
local COMMANDS = {
  completion = completion_command,
  chat = chat_command,
}

--- Formats a response string to extract the chat-gpt response (or error) from the API response. Includes logic to be API agnostic for either the completion or the chat API
---@param response_json table
---@param split boolean
---@return string
M.parse_response = function(response_json, split)
  if not response_json or response_json == "" or response_json.error then
    if response_json.error ~= nil then
      return response_json.error.message
    else
      error "Failed to get JSON response."
    end
  end

  local choice = response_json.choices[1]

  if choice ~= nil then
    local text = choice.text or choice.message.content
    if not split or split == "" then
      return text
    end
    return string_util.format_string_with_line_breaks(text)
  end

  return vim.inspect(response_json)
end

--- Uses vim api to get filetype of current buffer
---@return string
M.get_filetype = function()
  return vim.bo.filetype
end

--- Returns default question based on filetype of buffer
---@param question string|nil
---@return string
M.get_question = function(question)
  if question == nil or question == "" then
    local ft = M.get_filetype()
    question = _G.ExplainIt.config.default_prompts[ft]
    if not question then
      question = "Answer this question:"
    end
  end
  return question
end

--- Uses a local command and replaces placeholder text with the ChatGPT API Key from an env var and placeholder text with the prompt
---@param escaped_input string
---@param question string
---@param command_type commands
---@param opts table Optional parameters
---@return string
M.get_formatted_command = function(escaped_input, question, command_type, opts)
  local command_str = ""

  D.log("chat-gpt.get_formatted_command", "Using model: " .. _G.ExplainIt.config.openai_chat_model)
  if command_type == "chat_command" then
    command_str = COMMANDS.chat:gsub("##MODEL##", _G.ExplainIt.config.openai_chat_model)
  else
    command_str = COMMANDS.completion:gsub("##MODEL##", _G.ExplainIt.config.openai_completion_model)
  end
  command_str = command_str:gsub("##MODEL_BASE_API##", _G.ExplainIt.config.model_base_api)

  -- determine if we are using grok or openai. if the base api is api.x.ai, then we are using grok
  local is_grok = string.find(_G.ExplainIt.config.model_base_api, "api.x.ai") ~= nil

  local api_key = os.getenv "CHAT_GPT_API_KEY"
  if is_grok then
    D.log("chat-gpt.get_formatted_command", "Using Grok API")
    local grok_api_key = os.getenv "GROK_API_KEY"
    api_key = grok_api_key
  else
    D.log("chat-gpt.get_formatted_command", "Using OpenAI API")
  end
  if not api_key or api_key == "" then
    D.log("chat-gpt.get_formatted_command", "Failed to get CHAT_GPT_API_KEY")
    error "Failed to get API key. Is CHAT_GPT_API_KEY env var set?"
  end
  local populated_token = string.gsub(command_str, "##API_KEY##", api_key)

  local populated_question = string.gsub(populated_token, "##OPTIONAL_QUESTION##", question)
  local populated_prompt = string.gsub(populated_question, "##ESCAPED_INPUT##", escaped_input)
  local with_tokens =
    string.gsub(populated_question, "##TOKEN_LIMIT##", _G.ExplainIt.config.token_limit)

  D.log("chat-gpt.get_formatted_command", "prompt: %s", with_tokens)
  return populated_prompt
end

--- Formats input in order to make an API call to ChatGPT, makes the API call, writes the prompt and response to a file, then returns the response
---@param escaped_input any
---@param optional_question any
---@param prompt_type any
---@return AIResponse
M.call_gpt = function(escaped_input, optional_question, prompt_type)
  D.log(
    "chat-gpt.call_chat_gpt",
    "Making API call to /v1/completions API with prompt: %s",
    escaped_input
  )
  local question = M.get_question(optional_question)
  local formatted_prompt = M.get_formatted_command(escaped_input, question, prompt_type)
  D.log("chat-gpt.call_chat_gpt", "prompt: %s", formatted_prompt)
  local response = system.make_system_call_with_retry(formatted_prompt)
  local ai_response = {
    question = question,
    input = escaped_input,
    response = M.parse_response(response, false),
  }
  D.log("chat-gpt.call_chat_gpt", "ai_response: %s", vim.inspect(ai_response))
  M.write_ai_response_to_file(ai_response)
  return ai_response
end

--- Writes the prompt and response to a file so that Chat-GPT responses can be persisted
---@param ai_response AIResponse
---@return string
M.write_ai_response_to_file = function(ai_response)
  local temp_file = system.make_temp_file() or "/tmp/explain_it_output.txt"
  local fh = io.open(string.gsub(temp_file, "\n", ""), "w+")
  if fh ~= nil then
    fh:write "## Question:\n"
    fh:write(string.format("%s\n\n", ai_response.question))
    fh:write "## Input:\n"
    fh:write(string.format("%s\n\n", ai_response.input))
    fh:write "## Response:\n"
    fh:write(string.format("%s", ai_response.response))
    fh:close()
  end
  print("Response written to: " .. temp_file)
  return temp_file
end

return M


--   Question:
--   I have this function in lua. I also have a table called opts, which has optional options that may or may not be included. If included, I wish to use them from the opts table. Otherwise I wish to use t...

--   Input:
--   --- Uses a local command and replaces placeholder text with the ChatGPT API Key from an env var and placeholder text with the prompt\\n---@param escaped_input string\\n---@param question string\\n---@...

--   Response:
--   To modify your Lua function to use values from the `opts` table when available, and fallback to the `_G` table otherwise, you can use a helper function to check for the existence of keys in `opts`.
-- Here's how you can adjust your function:
-- ```lua
-- --- Uses a local command and replaces placeholder text with the ChatGPT API Key from an env var and placeholder text with the prompt
-- ---@param escaped_input string
-- ---@param question string
-- ---@param command_type commands
-- ---@param opts table Optional parameters
-- ---@return string
-- M.get_formatted_command = function(escaped_input, question, command_type, opts)
--   opts = opts or {}  -- Ensure opts is a table even if not provided
--   local function get_opt(key, default)
--     return opts[key] or _G.ExplainIt.config[key] or default
--   end
--   local command_str = ""
--   D.log("chat-gpt.get_formatted_command", "Using model: " .. get_opt("openai_chat_model"))
--   if command_type == "chat_command" then
--     command_str = COMMANDS.chat:gsub("##MODEL##", get_opt("openai_chat_model"))
--   else
--     command_str = COMMANDS.completion:gsub("##MODEL##", get_opt("openai_completion_model"))
--   end
--   command_str = command_str:gsub("##MODEL_BASE_API##", get_opt("model_base_api"))
--   -- Determine if we are using Grok or OpenAI
--   local is_grok = string.find(get_opt("model_base_api", ""), "api.x.ai") ~= nil
--   local api_key = os.getenv("CHAT_GPT_API_KEY")
--   if is_grok then
--     D.log("chat-gpt.get_formatted_command", "Using Grok API")
--     local grok_api_key = os.getenv("GROK_API_KEY")
--     api_key = grok_api_key
--   else
--     D.log("chat-gpt.get_formatted_command", "Using OpenAI API")
--   end
--   if not api_key or api_key == "" then
--     D.log("chat-gpt.get_formatted_command", "Failed to get API key")
--     error("Failed to get API key. Is CHAT_GPT_API_KEY or GROK_API_KEY env var set?")
--   end
--   local populated_token = string.gsub(command_str, "##API_KEY##", api_key)
--   local populated_question = string.gsub(populated_token, "##OPTIONAL_QUESTION##", question)
--   local populated_prompt = string.gsub(populated_question, "##ESCAPED_INPUT##", escaped_input)
--   local with_tokens = string.gsub(populated_prompt, "##TOKEN_LIMIT##", get_opt("token_limit", "1024"))
--   D.log("chat-gpt.get_formatted_command", "prompt: " .. with_tokens)
--   return populated_prompt
-- end
-- ```
-- ### Key Changes:
-- 1. **Added `opts` Parameter**: The function now accepts an `opts` table as an optional parameter.
-- 2. **Helper Function `get_opt`**: This function checks if a key exists in `opts`, if not, it falls back to `_G.ExplainIt.config`, and if that's also not available, it uses a default value.
-- 3. **Usage of `get_opt`**: Replaced direct references to `_G.ExplainIt.config` with `get_opt` calls to fetch values from `opts` or `_G.ExplainIt.config`.
--  This approach allows you to pass an `opts` table with specific configurations when calling `get_formatted_command`, and it will use those values if provided, otherwise falling back to the global
-- configuration or a default value. Remember to adjust the default values in `get_opt` calls if necessary.
--   
