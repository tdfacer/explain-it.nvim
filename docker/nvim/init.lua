local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "tdfacer/explain-it.nvim",
    dependencies = "rcarriga/nvim-notify",
    config = function()
      require("explain-it").setup {
        -- Prints useful log messages
        debug = true,
        -- Customize notification window width
        max_notification_width = 90,
        -- Retry API calls
        max_retries = 3,
        -- Customize response text file persistence location
        output_directory = "/tmp/chat_output",
        -- Toggle splitting responses in notification window
        split_responses = true,
        -- Set token limit to prioritize keeping costs low, or increasing quality/length of responses
        token_limit = 2000,
      }
    end,
  },
}

require("lazy").setup(plugins)
