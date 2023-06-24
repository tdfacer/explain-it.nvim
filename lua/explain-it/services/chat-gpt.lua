local system = require "explain-it.system"
local string_util = require "explain-it.util.strings"

local D = require "explain-it.util.debug"

local M = {}

---@alias completion_command string
local completion_command = [[
  curl https://api.openai.com/v1/completions \
    2>/dev/null \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ##API_KEY##" \
    -d '{
      "model": "text-davinci-003",
      "prompt": "##PROMPT##\n##LINES##",
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
      "model": "gpt-3.5-turbo-0301",
      "messages": [{"role": "user", "content": "##PROMPT##\n##LINES##"}],
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
---@return string|table
M.format_response = function(response_json, split)
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

  return response_json
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
  local ft = M.get_filetype()
  if question == nil or question == "" then
    if M.get_filetype() == "markdown" then
      question = "summarize this block of text:"
    else
      question = "what does this code do?"
    end
  end
  return question
end

--- Uses a local command and replaces placeholder text with the ChatGPT API Key from an env var and placeholder text with the prompt
---@param escaped_prompt string
---@param question string
---@param command_type commands
---@return string
M.get_formatted_prompt = function(escaped_prompt, question, command_type)
  local command_str = command_type == "chat_command" and COMMANDS.chat or COMMANDS.completion
  local api_key = os.getenv "CHAT_GPT_API_KEY"
  if not api_key or api_key == "" then
    D.log("chat-gpt.get_formatted_prompt", "Failed to get CHAT_GPT_API_KEY")
    error "Failed to get API key. Is CHAT_GPT_API_KEY env var set?"
  end
  local populated_token = string.gsub(command_str, "##API_KEY##", api_key)

  local populated_question = string.gsub(populated_token, "##PROMPT##", question)
  local populated_prompt = string.gsub(populated_question, "##LINES##", escaped_prompt)
  local with_tokens =
    string.gsub(populated_question, "##TOKEN_LIMIT##", _G.ExplainIt.config.token_limit)

  D.log("chat-gpt.get_formatted_prompt", "prompt: %s", with_tokens)
  return populated_prompt
end

--- Formats input in order to make an API call to ChatGPT, makes the API call, writes the prompt and response to a file, then returns the response
---@param escaped_input any
---@param optional_question any
---@param prompt_type any
---@return string
M.call_gpt = function(escaped_input, optional_question, prompt_type)
  D.log(
    "chat-gpt.call_chat_gpt",
    "Making API call to /v1/completions API with prompt: %s",
    escaped_input
  )
  local question = M.get_question(optional_question)
  local formatted_prompt = M.get_formatted_prompt(escaped_input, question, prompt_type)
  D.log("chat-gpt.call_chat_gpt", "prompt: %s", formatted_prompt)
  local json = system.make_system_call_with_retry(formatted_prompt)
  M.write_prompt_and_response_to_file(question, M.format_response(json, false))
  return string_util.truncate_string(question, _G.ExplainIt.config.max_notification_width)
    .. "\n\n"
    .. M.format_response(json, _G.ExplainIt.config.split_responses)
end

--- Writes the prompt and response to a file so that Chat-GPT responses can be persisted
---@param prompt string
---@param response any
---@return string
M.write_prompt_and_response_to_file = function(prompt, response)
  local temp_file = system.make_temp_file() or "/tmp/explain_it_output.txt"
  local fh = io.open(string.gsub(temp_file, "\n", ""), "w+")
  if fh ~= nil then
    fh:write(string.format("%s\n\n", prompt))
    fh:write "\n\n"
    fh:write(response)
    fh:close()
  end
  print("Response written to: " .. temp_file)
  return temp_file
end

return M
