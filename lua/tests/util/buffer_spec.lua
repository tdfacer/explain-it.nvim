package.path = package.path
  .. ";../../explain-it/?.lua;../../explain-it/services/?.lua;../../explain-it/util/?.lua"

local buffer
local api
local mock = require "luassert.mock"

describe("util.selection", function()
  before_each(function()
    buffer = require "explain-it.util.buffer"
    api = mock(vim.api, true)
  end)

  after_each(function()
    mock.revert(api)
  end)

  describe("get_visual_selection", function()
    it("Should return the content of the 'v' register", function()
      api.nvim_command.on_call_with('noau normal! "vy"').returns(nil)
      api.nvim_call_function.on_call_with("getreg", { "v" }).returns "test content"

      local actual = buffer.get_visual_selection()

      assert.equal("test content", actual)
    end)
  end)

  describe("get_buffer_lines", function()
    it("Should return all lines in the current buffer", function()
      api.nvim_buf_get_lines
        .on_call_with(0, 0, vim.api.nvim_buf_line_count(0), false)
        .returns { "line 1", "line 2", "line 3" }

      local actual = buffer.get_buffer_lines()

      assert.same({ "line 1", "line 2", "line 3" }, actual)
    end)
  end)
end)
