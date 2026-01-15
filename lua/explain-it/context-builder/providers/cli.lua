local BaseProvider = require("explain-it.context-builder.providers.base")

local M = {}

--- Create a generic CLI provider from configuration
---@param config table Provider configuration from setup
---@return AIProvider
function M.create_from_config(name, config)
  return BaseProvider.new {
    name = name,
    command = config.command,
    args = config.args,
    streaming = config.streaming or false,

    format_input = config.format_input or function(context, instruction)
      -- Default format: context followed by instruction
      local formatted = ""

      if context and context ~= "" then formatted = formatted .. "Context:\n" .. context .. "\n\n" end

      formatted = formatted .. "Instruction: " .. instruction

      return formatted
    end,

    parse_response = config.parse_response or function(output)
      -- Default: clean up common artifacts
      -- Remove potential shell prompt characters at start of lines
      output = output:gsub("^[>$#] ", "")
      -- Trim whitespace
      output = output:gsub("^%s+", ""):gsub("%s+$", "")
      return output
    end,

    validate = function()
      if not config.command or config.command == "" then return false, "No command specified for provider " .. name end

      -- Check if command is available
      local handle = io.popen("command -v " .. config.command .. " 2>/dev/null")
      if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result ~= "" then return true end
      end

      return false, "Command not found: " .. config.command .. ". Please ensure it is installed and in PATH."
    end,
  }
end

--- Predefined configurations for common CLI tools
M.presets = {
  aichat = {
    command = "aichat",
    args = { "--no-stream" },
    streaming = false,
  },

  llm = {
    command = "llm",
    args = { "prompt", "-m", "gpt-4" },
    streaming = false,
  },

  ollama = {
    command = "ollama",
    args = { "run", "llama2" },
    streaming = true,
    parse_response = function(output)
      -- Ollama includes some control characters we need to strip
      output = output:gsub("\x1b%[[0-9;]*[mGKH]", "") -- Remove ANSI escape codes
      return output
    end,
  },

  anthropic = {
    command = "anthropic",
    args = { "complete", "--max-tokens", "2000" },
    streaming = false,
  },
}

--- Get a preset configuration by name
---@param name string Preset name
---@return table|nil
function M.get_preset(name) return M.presets[name] end

return M
