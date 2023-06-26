local M = {}

--- Takes a string of variable length as input, then formats the string by splitting it into words and inserting line breaks to ensure that each line is no longer than the max_width as defined in global settings
---@param str string
---@return string
function M.format_string_with_line_breaks(str)
  local formattedStr = ""
  local lineLength = 0
  local words = {}
  for line in str:gmatch("[^\r\n]+") do -- split string into lines
    if #line <= _G.ExplainIt.config.max_notification_width then
      formattedStr = formattedStr .. line .. "\n" -- preserve newline
      lineLength = 0
    else
      for word in line:gmatch("%S+") do -- split line into words
        if lineLength + #word > _G.ExplainIt.config.max_notification_width then
          formattedStr = formattedStr .. "\n" .. word
          lineLength = #word
        else
          formattedStr = formattedStr .. " " .. word
          lineLength = lineLength + #word + 1
        end
      end
      formattedStr = formattedStr .. "\n" -- preserve newline
      lineLength = 0
    end
  end
  local stripped, _ = string.gsub(formattedStr, "^%s+", "") -- remove leading whitespace
  local no_trailing_newline, _ = stripped:gsub("\n$", "") -- remove trailing newline
  return no_trailing_newline
end

--- Takes a string as input and returns a truncated version of the string if it is longer than 77 characters. The truncated version includes an ellipsis ("...") at the end. If the string is 77 characters or shorter, the function simply returns the original string. The code also includes comments that describe the function's input and output parameters. Finally, the code returns the module "M".
---@param str string
---@return string
M.truncate_string = function(str, len)
  if string.len(str) > len then
    return string.sub(str, 1, len) .. "..."
  end
  return str
end

return M
