local M = {}

--- Escapes characters so that they can be included in a JSON body
---@param input any
---@return string
M.escape = function(input)
  local matches = {
    ['"'] = '\\"',
    ["'"] = "'\\''",
    ["\n"] = "\\\n",
    ["\t"] = "  ",
    ["\\"] = "\\\\",
  }
  local res, _ = string.gsub(input, ".", matches)
  return res
end

--- Escapes a string value or all string values on an input table
---@param input string|{ [string]: string }
---@return string
M.get_escaped_string = function(input)
  if type(input) == "table" then
    local escaped = {}
    for i, v in ipairs(input) do
      escaped[i] = M.escape(v)
    end
    return table.concat(escaped, "\\n")
  end
  return M.escape(input)
end

return M
