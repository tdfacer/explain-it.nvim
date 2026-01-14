local M = {}

--- Base provider interface for AI providers
---@class AIProvider
---@field name string Provider identifier
---@field command string|fun(context: string, instruction: string): string CLI command or function returning command
---@field args table Command arguments
---@field streaming boolean Whether provider supports streaming
---@field format_input fun(context: string, instruction: string): string Format the input for the provider
---@field parse_response fun(output: string): string Parse the provider's response
---@field validate fun(): boolean, string|nil Validate provider configuration

--- Create a new provider instance
---@param config table Provider configuration
---@return AIProvider
function M.new(config)
  local provider = {
    name = config.name,
    command = config.command,
    args = config.args or {},
    streaming = config.streaming or false,
    format_input = config.format_input or function(context, instruction)
      -- Default: concatenate context and instruction
      return context .. "\n\n" .. instruction
    end,
    parse_response = config.parse_response or function(output)
      -- Default: return output as-is
      return output
    end,
    validate = config.validate or function()
      -- Default validation
      if not config.command then
        return false, "Command not specified"
      end
      -- Check if command exists
      local handle = io.popen("which " .. (type(config.command) == "string" and config.command or "echo"))
      if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result ~= "" then
          return true
        end
      end
      return false, "Command not found: " .. tostring(config.command)
    end
  }

  setmetatable(provider, { __index = M })
  return provider
end

--- Execute the provider with given context and instruction
---@param context string The context (files, snippets, etc.)
---@param instruction string The user's instruction
---@param callback fun(success: boolean, response: string) Callback with result
function M:execute(context, instruction, callback)
  -- Format input
  local input = self.format_input(context, instruction)

  -- Build command
  local cmd
  if type(self.command) == "function" then
    cmd = self.command(context, instruction)
  else
    cmd = self.command
  end

  -- Add arguments
  local full_cmd = { cmd }
  for _, arg in ipairs(self.args) do
    table.insert(full_cmd, arg)
  end

  -- Execute command
  local system = require("explain-it.system")
  local temp_file = system.make_temp_file("context_input")

  -- Write input to temp file
  local file = io.open(temp_file, "w")
  if not file then
    callback(false, "Failed to create temp file")
    return
  end
  file:write(input)
  file:close()

  -- Execute with input from file
  local cmd_str = table.concat(full_cmd, " ") .. " < " .. temp_file

  vim.fn.jobstart(cmd_str, {
    stdout_buffered = not self.streaming,
    on_stdout = function(_, data, _)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        local parsed = self.parse_response(output)
        callback(true, parsed)
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        local error_msg = table.concat(data, "\n")
        callback(false, "Error: " .. error_msg)
      end
    end,
    on_exit = function(_, exit_code, _)
      -- Clean up temp file
      os.remove(temp_file)

      if exit_code ~= 0 then
        callback(false, "Command exited with code: " .. exit_code)
      end
    end,
  })
end

--- Get a human-readable description of the provider
---@return string
function M:describe()
  return string.format("Provider: %s (Command: %s)", self.name, tostring(self.command))
end

return M