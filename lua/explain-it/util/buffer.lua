local M = {}

---Yank current visual selection into the 'v' register
---Note that this makes no effort to preserve this register
---Credit: tjdevries
---@return string
M.get_visual_selection = function()
  vim.cmd 'noau normal! "vy"'
  return vim.fn.getreg "v"
end

---Get all lines in current buffer
---@return string
M.get_buffer_lines = function()
  local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return content
end

return M
