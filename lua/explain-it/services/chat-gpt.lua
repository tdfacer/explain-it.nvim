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
  curl https://api.openai.com/v1/completions \
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
local chat_command = [[
  curl https://api.openai.com/v1/chat/completions \
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
---@return string
M.get_formatted_command = function(escaped_input, question, command_type)
  local command_str = ""
  if command_type == "chat_command" then
    command_str = COMMANDS.chat:gsub("##MODEL##", _G.ExplainIt.config.openai_chat_model)
  else
    command_str = COMMANDS.completion:gsub("##MODEL##", _G.ExplainIt.config.openai_completion_model)
  end
  local api_key = os.getenv "CHAT_GPT_API_KEY"
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
