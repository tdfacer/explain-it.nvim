-- Generates `doc/explain-it.txt` with mini.doc. Run via `make documentation`.
-- Run with `nvim -l` so any error exits non-zero and fails CI.
vim.opt.rtp:append(vim.fn.getcwd())
vim.opt.rtp:append("deps/mini.nvim")

local minidoc = require("mini.doc")
minidoc.setup()

-- Only document the public API. The default input would pick up every Lua file,
-- including the vendored `lua/morph.lua` and the test suite.
minidoc.generate({
  "lua/explain-it/init.lua",
  "lua/explain-it/config.lua",
}, "doc/explain-it.txt")
