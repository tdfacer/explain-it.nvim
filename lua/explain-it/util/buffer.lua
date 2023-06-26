local M = {}

--- Yank current visual selection into the 'v' register
--- Note that this makes no effort to preserve this register
--- Credit: tjdevries
---@return string
M.get_visual_selection = function()
  vim.cmd 'noau normal! "vy"'

  return vim.api.nvim_call_function("getreg", { "v" })
end

--- Get all lines in current buffer
---@return string
M.get_buffer_lines = function()
  local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return content
end

---writes content to buffer
---@param bufnr number
---@param content string
M.append_buffer_lines = function(bufnr, content)
  local lines = {}
  for line in content:gmatch "[^\n]+" do
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
end

return M
