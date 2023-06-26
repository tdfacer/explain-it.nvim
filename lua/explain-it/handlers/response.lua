local strings = require "explain-it.util.strings"
local notify = require "notify"

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

  local replaced_question = notification_template:gsub("##QUESTION##", question)
  local replaced_input = replaced_question:gsub("##INPUT##", input)
  local replaced_response = replaced_input:gsub("##RESPONSE##", response)

  notify(replaced_response)
end

return M
