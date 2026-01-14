local mock = require "luassert.mock"
local stub = require "luassert.stub"

local ExplainIt = require "explain-it"

describe("Context Builder", function()
  before_each(function()
    -- Mock vim.notify to avoid actual notifications during tests
    stub(vim, "notify")
    stub(vim.api, "nvim_create_buf")
    stub(vim.api, "nvim_buf_set_name")
    stub(vim.api, "nvim_win_set_buf")
    stub(vim.api, "nvim_win_set_width")
    stub(vim, "cmd")

    -- Return a mock buffer number
    vim.api.nvim_create_buf.returns(1)
  end)

  after_each(function()
    vim.notify:revert()
    vim.api.nvim_create_buf:revert()
    vim.api.nvim_buf_set_name:revert()
    vim.api.nvim_win_set_buf:revert()
    vim.api.nvim_win_set_width:revert()
    vim.cmd:revert()
  end)

  describe("open_context_builder", function()
    it("should show warning when context builder is not enabled", function()
      -- Setup with context builder disabled
      ExplainIt.setup({
        context_builder = { enabled = false }
      })

      -- Try to open context builder
      ExplainIt.open_context_builder()

      -- Should show warning notification
      assert.stub(vim.notify).was_called_with(
        "Context Builder is not enabled. Set context_builder.enabled = true in setup()",
        vim.log.levels.WARN
      )
    end)

    it("should open context builder when enabled", function()
      -- Setup with context builder enabled
      ExplainIt.setup({
        context_builder = {
          enabled = true,
          window_config = {
            split = "vertical",
            width = 0.4
          }
        }
      })

      -- Mock the ContextBuilder module
      package.loaded["explain-it.context-builder"] = {
        open = function(opts) end
      }
      local context_builder_stub = stub(package.loaded["explain-it.context-builder"], "open")

      -- Open context builder
      ExplainIt.open_context_builder({ test = true })

      -- Should call ContextBuilder.open
      assert.stub(context_builder_stub).was_called_with({ test = true })

      -- Cleanup
      context_builder_stub:revert()
      package.loaded["explain-it.context-builder"] = nil
    end)
  end)

  describe("Context Builder UI", function()
    it("should create a new buffer with correct settings", function()
      -- Setup
      ExplainIt.setup({
        context_builder = {
          enabled = true,
          window_config = {
            split = "vertical",
            width = 0.4
          }
        }
      })

      -- Load the actual context builder module
      local ContextBuilder = require("explain-it.context-builder")

      -- Mock Morph since it's in parent directory
      package.loaded["morph"] = {
        new = function(buf)
          return {
            mount = function(self, tree) end
          }
        end,
        h = function(name, attrs, children)
          return { type = "element", name = name, attrs = attrs, children = children }
        end
      }

      -- Mock vim.bo and vim.o
      vim.bo = {}
      vim.o = { columns = 120 }

      -- Call open
      ContextBuilder.open()

      -- Verify buffer was created
      assert.stub(vim.api.nvim_create_buf).was_called_with(false, true)

      -- Verify buffer name was set
      assert.stub(vim.api.nvim_buf_set_name).was_called_with(1, "AI Context Builder")

      -- Verify split was created
      assert.stub(vim.cmd).was_called_with("vsplit")

      -- Verify window width was set (40% of 120 = 48)
      assert.stub(vim.api.nvim_win_set_width).was_called_with(0, 48)

      -- Cleanup
      package.loaded["morph"] = nil
      vim.bo = nil
      vim.o = nil
    end)
  end)
end)