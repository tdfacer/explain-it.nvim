local plenary_dir = os.getenv "PLENARY_DIR" or "./deps/plenary.nvim"
local notify_dir = os.getenv "NOTIFY_DIR" or "./deps/nvim-notify"

local deps = {
  plenary_dir,
  notify_dir,
}

local function check_dep_exists(dep_dir)
  local is_not_a_directory = vim.fn.isdirectory(dep_dir) == 0
  if is_not_a_directory then
    error(string.format("Dependency does not exist: %s", dep_dir), vim.log.levels.ERROR)
    os.exit(1)
  end
end

vim.opt.rtp:append "."
for _, dep in ipairs(deps) do
  check_dep_exists(dep)
  vim.opt.rtp:append(dep)
end

vim.opt.termguicolors = true
vim.cmd "runtime plugin/plenary.vim"
require "plenary.busted"

require("notify").setup {
  background_colour = "#000000",
}

local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>z", require("explain-it").explain_it, opts)
vim.keymap.set("v", "<space>z", require("explain-it").explain_it, opts)
vim.keymap.set("n", "<space>Z", function()
  require("explain-it").explain_it { custom_prompt = true }
end, opts)
-- vim.keymap.set("v", "<space>Z", function() require"explain-it".explain_it_visual({custom_prompt = true}) end, opts)
vim.keymap.set("v", "<space>Z", function()
  require("explain-it").explain_it { custom_prompt = true, is_visual = true }
end, opts)
vim.keymap.set("n", "<space>x", function()
  require("explain-it").explain_it { custom_prompt = false, api_type = "chat" }
end, opts)
vim.keymap.set("v", "<space>x", function()
  require("explain-it").explain_it { custom_prompt = false, api_type = "chat", is_visual = true }
end, opts)
vim.keymap.set("n", "<space>X", function()
  require("explain-it").explain_it { custom_prompt = true, api_type = "chat" }
end, opts)
vim.keymap.set("v", "<space>X", function()
  require("explain-it").explain_it { custom_prompt = true, api_type = "chat", is_visual = true }
end, opts)
