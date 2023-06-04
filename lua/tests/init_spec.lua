local stub = require "luassert.stub"

local ExplainIt = require "explain-it"
local buff = require "explain-it.util.buffer"
local escape = require "explain-it.util.escape"
local chat_gpt = require "explain-it.services.chat-gpt"
local notify = require "notify"

describe("ExplainIt", function()
  before_each(function()
    stub(buff, "get_visual_selection")
    stub(buff, "get_buffer_lines")
    stub(escape, "get_escaped_string")
    stub(ExplainIt, "call_chat_gpt")
    stub(vim.ui, "input")
  end)
  after_each(function()
    buff.get_visual_selection:revert()
    buff.get_buffer_lines:revert()
    escape.get_escaped_string:revert()
    ExplainIt.call_chat_gpt:revert()
    vim.ui.input:revert()
  end)
  describe("setup", function()
    it("should set up the config with user-provided options", function()
      local opts = { foo = "bar" }
      ExplainIt.setup(opts)
      assert.is_equal(opts.foo, _G.ExplainIt.config.foo)
    end)

    it("should call call_chat_gpt with buffer lines if is_visual is false", function()
      buff.get_buffer_lines.returns "buffer lines"
      escape.get_escaped_string.returns "escaped string"
      ExplainIt.explain_it { is_visual = false }
      assert.stub(ExplainIt.call_chat_gpt).was_called_with {
        api_type = "completion",
        custom_prompt = false,
        text = "escaped string",
        is_visual = false,
      }
    end)

    it("should call call_chat_gpt with visual selection if is_visual is true", function()
      buff.get_visual_selection.returns "visual selection"
      escape.get_escaped_string.returns "escaped string"
      ExplainIt.explain_it { is_visual = true }
      assert.stub(ExplainIt.call_chat_gpt).was_called_with {
        api_type = "completion",
        custom_prompt = false,
        text = "escaped string",
        is_visual = true,
      }
    end)

    -- WIP vim.ui wonkiness
    --   it("should call call_chat_gpt with custom prompt if custom_prompt is true", function()
    --     buff.get_buffer_lines.returns("buffer lines")
    --     escape.get_escaped_string.returns("escaped string")
    --     vim.ui.input = function(tbl, fn)
    --       for k, _ in tbl do
    --         print("### vim.ui.input k: " .. k)
    --       end
    --       fn()
    --     end
    --     ExplainIt.explain_it({ custom_prompt = true })
    --     assert.stub(ExplainIt.call_chat_gpt).was_not_called()
    --     vim.ui.input.calls[1].cb("custom prompt")
    --     assert.stub(ExplainIt.call_chat_gpt).was_called_with({ text = "escaped string", custom_prompt = "custom prompt" })
    --   end)
  end)
end)

describe("call_chat_gpt", function()
  before_each(function()
    stub(chat_gpt, "call_gpt")
    stub(notify, "notify")
  end)

  after_each(function()
    chat_gpt.call_gpt:revert()
    notify.notify:revert()
  end)

  it("should call chat_gpt.call_gpt with completion api if api_type is completion", function()
    ExplainIt.call_chat_gpt { api_type = "completion", text = "text" }
    assert.stub(chat_gpt.call_gpt).was_called_with("text", nil, "command")
  end)

  it("should call chat_gpt.call_gpt with chat api if api_type is not completion", function()
    ExplainIt.call_chat_gpt { api_type = "chat", text = "text" }
    assert.stub(chat_gpt.call_gpt).was_called_with("text", nil, "chat_command")
  end)

  it("should call chat_gpt.call_gpt with custom prompt if custom_prompt is provided", function()
    ExplainIt.call_chat_gpt {
      api_type = "completion",
      text = "text",
      custom_prompt = "custom prompt",
    }
    assert.stub(chat_gpt.call_gpt).was_called_with("text", "custom prompt", "command")
  end)

  it("should call notify with the response from chat_gpt.call_gpt", function()
    chat_gpt.call_gpt.returns "response"
    ExplainIt.call_chat_gpt { api_type = "completion", text = "text" }
    assert.stub(notify.notify).was_called_with("response", nil, nil)
  end)
end)
