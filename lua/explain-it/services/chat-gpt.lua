local string_util = require("explain-it.util.strings")
local system = require("explain-it.system")

local D = require("explain-it.util.debug")

local M = {}

---@class AIResponse
---@field question string
---@field input string
---@field response string

---@alias completion_command "completion_command"
---@alias chat_command "chat_command"
---@alias commands completion_command|chat_command

---@class ExplainItRequest
---@field cmd string[] curl argv, run directly without a shell
---@field body string JSON request body, passed to curl on stdin

--- Extracts the response text (or error) from an API response. Handles the OpenAI chat and
--- completion APIs and the Anthropic Messages API.
---@param response_json table
---@param split boolean
---@return string
M.parse_response = function(response_json, split)
  if not response_json or response_json == "" or response_json.error then
    if response_json.error ~= nil then
      return response_json.error.message
    else
      error("Failed to get JSON response.")
    end
  end

  local text
  if response_json.type == "message" then
    text = M.get_anthropic_text(response_json)
  elseif response_json.choices and response_json.choices[1] then
    local choice = response_json.choices[1]
    text = choice.text or choice.message.content
  else
    return vim.inspect(response_json)
  end

  if not split or split == "" then return text end
  return string_util.format_string_with_line_breaks(text)
end

--- Joins the text blocks of an Anthropic Messages API response. Other block types (such as
--- thinking) are skipped. A refusal is reported instead of any partial text.
---@param response_json table
---@return string
M.get_anthropic_text = function(response_json)
  if response_json.stop_reason == "refusal" then
    local category = vim.tbl_get(response_json, "stop_details", "category")
    return "Claude declined this request" .. (type(category) == "string" and (" (" .. category .. ")") or "") .. "."
  end

  local parts = {}
  for _, block in ipairs(response_json.content or {}) do
    if block.type == "text" then table.insert(parts, block.text) end
  end
  local text = table.concat(parts)
  if response_json.stop_reason == "max_tokens" then
    text = text .. "\n\n[Response truncated: hit anthropic_max_tokens]"
  end
  return text
end

--- Uses vim api to get filetype of current buffer
---@return string
M.get_filetype = function() return vim.bo.filetype end

--- Returns default question based on filetype of buffer
---@param question string|nil
---@return string
M.get_question = function(question)
  if question == nil or question == "" then
    local ft = M.get_filetype()
    question = _G.ExplainIt.config.default_prompts[ft]
    if not question then question = "Answer this question:" end
  end
  return question
end

--- Builds the JSON-serializable request body for the configured provider
---@param input string raw (unescaped) text to send
---@param question string
---@param command_type commands
---@return table
M.build_request_body = function(input, question, command_type)
  local config = _G.ExplainIt.config
  local content = question .. "\n" .. input
  if config.provider == "anthropic" then
    -- The Messages API covers both the chat and completion use cases.
    return {
      model = config.anthropic_model,
      max_tokens = config.anthropic_max_tokens,
      messages = { { role = "user", content = content } },
      fallbacks = config.anthropic_fallbacks or nil,
    }
  end
  if command_type == "chat_command" then
    return {
      model = config.openai_chat_model,
      messages = { { role = "user", content = content } },
      max_completion_tokens = 20000,
    }
  end
  return {
    model = config.openai_completion_model,
    prompt = content,
    max_tokens = 2000,
  }
end

--- Reads an API key from the environment, erroring if it is missing
---@param env_var string
---@return string
local function get_api_key(env_var)
  local api_key = os.getenv(env_var)
  if not api_key or api_key == "" then
    D.log("chat-gpt.build_request", "Failed to get %s", env_var)
    error(string.format("Failed to get API key. Is %s env var set?", env_var))
  end
  return api_key
end

--- Builds the curl argv and JSON body for an API call. The body is encoded with vim.json and sent on
--- stdin, so the input never passes through a shell and needs no manual escaping.
---@param input string raw (unescaped) text to send
---@param question string
---@param command_type commands
---@return ExplainItRequest
M.build_request = function(input, question, command_type)
  local config = _G.ExplainIt.config
  local url, headers
  if config.provider == "anthropic" then
    local base_api = (config.anthropic_base_api or "https://api.anthropic.com/v1"):gsub("/$", "")
    url = base_api .. "/messages"
    headers = {
      "x-api-key: " .. get_api_key("ANTHROPIC_API_KEY"),
      "anthropic-version: 2023-06-01",
    }
    if config.anthropic_fallbacks then table.insert(headers, "anthropic-beta: server-side-fallback-2026-07-01") end
  else
    local base_api = (config.model_base_api or "https://api.openai.com/v1"):gsub("/$", "")
    url = base_api .. (command_type == "chat_command" and "/chat/completions" or "/completions")
    headers = { "Authorization: Bearer " .. get_api_key("CHAT_GPT_API_KEY") }
  end

  local body = M.build_request_body(input, question, command_type)
  D.log_always("chat-gpt", "Using model: %s (api: %s, url: %s)", body.model, command_type, url)

  local cmd = { "curl", "--silent", url, "-H", "Content-Type: application/json" }
  for _, header in ipairs(headers) do
    vim.list_extend(cmd, { "-H", header })
  end
  vim.list_extend(cmd, { "--data-binary", "@-" })

  return { cmd = cmd, body = vim.json.encode(body) }
end

--- Formats input in order to make an API call to ChatGPT, makes the API call, writes the prompt and response to a file, then returns the response
---@param input string
---@param optional_question string|nil
---@param prompt_type commands
---@return AIResponse
M.call_gpt = function(input, optional_question, prompt_type)
  D.log("chat-gpt.call_chat_gpt", "Making API call with prompt: %s", input)
  local question = M.get_question(optional_question)
  local request = M.build_request(input, question, prompt_type)
  D.log("chat-gpt.call_chat_gpt", "body: %s", request.body)
  local response = system.make_system_call_with_retry(request.cmd, request.body)
  local ai_response = {
    question = question,
    input = input,
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
    fh:write("## Question:\n")
    fh:write(string.format("%s\n\n", ai_response.question))
    fh:write("## Input:\n")
    fh:write(string.format("%s\n\n", ai_response.input))
    fh:write("## Response:\n")
    fh:write(string.format("%s", ai_response.response))
    fh:close()
  end
  print("Response written to: " .. temp_file)
  return temp_file
end

--- Async version of call_gpt using callbacks
---@param input string
---@param optional_question string|nil
---@param prompt_type commands
---@param on_success fun(response: AIResponse) callback with result
---@param on_error fun(error: string) callback with error
M.call_gpt_async = function(input, optional_question, prompt_type, on_success, on_error)
  D.log("chat-gpt.call_gpt_async", "Making async API call with prompt: %s", input)

  local question = M.get_question(optional_question)
  local request = M.build_request(input, question, prompt_type)
  D.log("chat-gpt.call_gpt_async", "body: %s", request.body)

  -- Make async call
  system.make_async_system_call(request.cmd, function(response)
    -- Success callback
    vim.schedule(function()
      local success, result = pcall(vim.fn.json_decode, response)
      if success and result then
        local ai_response = {
          question = question,
          input = input,
          response = M.parse_response(result, false),
        }
        D.log("chat-gpt.call_gpt_async", "ai_response: %s", vim.inspect(ai_response))
        M.write_ai_response_to_file(ai_response)
        on_success(ai_response)
      else
        on_error("Failed to parse API response: " .. (response or "empty response"))
      end
    end)
  end, function(error)
    -- Error callback
    vim.schedule(function() on_error("API call failed: " .. error) end)
  end, request.body)
end

return M
