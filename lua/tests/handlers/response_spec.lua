local stub = require("luassert.stub")

-- Clear loaded modules to ensure we can mock properly
package.loaded["notify"] = nil
package.loaded["explain-it.handlers.response"] = nil

-- Create stub for notify
local notify_stub = stub()
package.loaded["notify"] = notify_stub

local response_handler = require("explain-it.handlers.response")

describe("notify", function()
  before_each(function()
    require("explain-it").setup {
      token_limit = 2000,
    }
  end)

  after_each(function() notify_stub:clear() end)

  it("should notify response", function()
    local ai_response = {
      question = "What is your name?",
      input = "My name is John",
      response = "Nice to meet you John",
    }
    local expected_notification = [[  Question:
  What is your name?

  Input:
  My name is John

  Response:
  Nice to meet you John
  ]]
    response_handler.notify_response(ai_response)
    assert.stub(notify_stub).was_called_with(expected_notification)
  end)

  it("should not notify response if ai_response is nil", function()
    response_handler.notify_response(nil)
    assert.stub(notify_stub).was_not_called()
  end)
end)
