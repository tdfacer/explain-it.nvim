-- credit: https://github.com/kiran94/s3edit.nvim/blob/main/lua/s3edit/system.lua
local M = {}
local D = require("explain-it.util.debug")

--- Makes a call into the underlying operating system
--- and reads the response
---@param command string the command to run
---@return string|nil result result of the command
M.make_system_call = function(command)
  local handle, err = io.popen(command)
  if err and err ~= nil then D.log("system.lua", "make sys call: err") end
  if handle == nil then
    D.log("system.lua", "make sys call: handle: was nil")
    vim.notify("could not run command " .. command)
    return nil
  end

  local result = handle:read("*a")
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
      if success then return result end
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

--- Makes an async system call using jobstart
---@param command string the command to run
---@param on_success fun(result: string) callback with result
---@param on_error fun(error: string) callback with error
---@return number job_id
M.make_async_system_call = function(command, on_success, on_error)
  local stdout_chunks = {}
  local stderr_chunks = {}

  local job_id = vim.fn.jobstart(command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data and #data > 0 then
        -- Remove empty last element if present
        if data[#data] == "" then table.remove(data, #data) end
        vim.list_extend(stdout_chunks, data)
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        if data[#data] == "" then table.remove(data, #data) end
        vim.list_extend(stderr_chunks, data)
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        local result = table.concat(stdout_chunks, "\n")
        on_success(result)
      else
        local error_msg = table.concat(stderr_chunks, "\n")
        on_error(error_msg or "Command failed with exit code: " .. exit_code)
      end
    end,
  })

  if job_id <= 0 then on_error("Failed to start job: " .. command) end

  return job_id
end

--- Creates a temporary file on the operating system
--- @return string
M.make_temp_file = function()
  local date_string = os.date("%Y-%m-%d_%H-%M-%S")
  local file = string.format("%s/%s.txt", ExplainIt.config.output_directory or "default", date_string)

  local temp_file = M.make_system_call(string.format("touch %s && echo %s", file, file))

  if not temp_file or temp_file == "" then error("failed to create temporary file") end
  local res, _ = string.gsub(temp_file, "\n", "")
  return res
end

return M
