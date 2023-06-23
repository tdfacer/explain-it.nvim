local plenary_dir = os.getenv("PLENARY_DIR") or "./deps/plenary.nvim"
local notify_dir = os.getenv("NOTIFY_DIR") or "./deps/nvim-notify"

local deps = {
  plenary_dir,
  notify_dir
}


local function check_dep_exists(dep_dir)
  vim.print("CHECKING: " .. dep_dir)
  local is_not_a_directory = vim.fn.isdirectory(dep_dir) == 0
  if is_not_a_directory then
    error(string.format("Dependency does not exist: %s", dep_dir), vim.log.levels.ERROR)
    os.exit(1)
  end
end

vim.opt.rtp:append(".")
for _, dep in ipairs(deps) do
  check_dep_exists(dep)
vim.opt.rtp:append(dep)
end

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
