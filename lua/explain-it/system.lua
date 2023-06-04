-- credit: https://github.com/kiran94/s3edit.nvim/blob/main/lua/s3edit/system.lua
local M = {}
local D = require "explain-it.util.debug"

--- Makes a call into the underlying operating system
--- and reads the response
---@param command string the command to run
---@return string|nil result result of the command
M.make_system_call = function(command)
  local handle, err = io.popen(command)
  if err and err ~= nil then
    D.log("system.lua", "make sys call: err")
  end
  if handle == nil then
    D.log("system.lua", "make sys call: handle: was nil")
    vim.notify("could not run command " .. command)
    return nil
  end

  local result = handle:read "*a"
  handle:close()
  return result
end

--- Wrapper around make_system_call that will retry failed requests
---@param command string
---@return table|lsp.ResponseError
M.make_system_call_with_retry = function(command)
  local response = nil
  local max_retries = _G.ExplainIt.config.max_retries
  local retry_count = 0
  while retry_count < max_retries do
    response = M.make_system_call(command)
    if response then
      local success, result = pcall(vim.fn.json_decode, response)
      if success then
        return result
      end
    end
    if response then
      retry_count = retry_count + 1
      print("failed to get response. Retry number: " .. tostring(retry_count))
    else
      break
    end
  end
  error(string.format("failed to get valid response after %s retries", retry_count))
end

--- Creates a temporary file on the operating system
--- @return string
M.make_temp_file = function()
  local date_string = os.date "%Y-%m-%d_%H-%M-%S"
  local file =
    string.format("%s/%s.txt", ExplainIt.config.output_directory or "default", date_string)

  local temp_file = M.make_system_call(string.format("touch %s && echo %s", file, file))

  if not temp_file or temp_file == "" then
    error "failed to create temporary file"
  end
  local res, _ = string.gsub(temp_file, "\n", "")
  return res
end

return M
