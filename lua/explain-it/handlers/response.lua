local strings = require "explain-it.util.strings"
local notify = require "notify"
local buffer = require "explain-it.util.buffer"

local M = {}

---Notifies response using notify
---@param ai_response AIResponse
---@return nil
M.notify_response = function(ai_response)
  if not ai_response then
    return nil
  end
  local notification_template = [[
  Question:
  ##QUESTION##

  Input:
  ##INPUT##

  Response:
  ##RESPONSE##
  ]]
  local should_split = _G.ExplainIt.config.split_responses
  local width = _G.ExplainIt.config.max_notification_width
  local question = should_split and strings.truncate_string(ai_response.question, width)
    or ai_response.question
  local input = should_split and strings.truncate_string(ai_response.input, width)
    or ai_response.input
  local response = should_split and strings.format_string_with_line_breaks(ai_response.response)
    or ai_response.response
  local with_percent = response:gsub("%%", "%%%%")

  local replaced_question = notification_template:gsub("##QUESTION##", question)
  local replaced_input = replaced_question:gsub("##INPUT##", input)
  local replaced_response = replaced_input:gsub("##RESPONSE##", with_percent)
  notify(replaced_response)
end

---Notifies response using notify
---@param ai_response AIResponse
---@return nil
M.append_buffer_response = function(ai_response)
  local bufnr = vim.api.nvim_get_current_buf()
  buffer.append_buffer_lines(bufnr, ai_response.response)
end

return M
