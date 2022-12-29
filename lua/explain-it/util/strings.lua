local M = {}

---Takes a string of variable length as input, then formats the string by splitting it into words and inserting line breaks to ensure that each line is no longer than the max_width as defined in global settings
---@param str string
---@return string
function M.format_string_with_line_breaks(str)
  local formattedStr = ""
  local lineLength = 0
  local words = {}
  for word in str:gmatch "%S+" do
    table.insert(words, word)
  end
  for _, word in ipairs(words) do
    if lineLength + #word > _G.ExplainIt.config.max_notification_width then
      formattedStr = formattedStr .. "\n" .. word
      lineLength = #word
    else
      formattedStr = formattedStr .. " " .. word
      lineLength = lineLength + #word + 1
    end
  end
  return formattedStr
end

---Takes a string as input and returns a truncated version of the string if it is longer than 77 characters. The truncated version includes an ellipsis ("...") at the end. If the string is 77 characters or shorter, the function simply returns the original string. The code also includes comments that describe the function's input and output parameters. Finally, the code returns the module "M".
---@param str string
---@return string
M.truncate_string = function(str, len)
  if string.len(str) > len then
    return string.sub(str, 1, len) .. "..."
  end
  return str
end

return M
