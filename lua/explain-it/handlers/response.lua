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
  local replaced_question = notification_template:gsub("##QUESTION##", ai_response.question)
  local replaced_input = replaced_question:gsub("##INPUT##", ai_response.input)
  local replaced_response = replaced_input:gsub("##RESPONSE##", ai_response.response)

  notify(replaced_response)
end

return M
