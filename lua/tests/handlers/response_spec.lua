local stub = require "luassert.stub"
local response_handler = require "explain-it.handlers.response"
local notify = require "notify"
describe("notify", function()
  before_each(function()
    stub(notify, "notify")
    require("explain-it").setup {
      token_limit = 2000,
    }
  end)

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
    assert.stub(notify.notify).was_called_with(expected_notification, nil, nil)
  end)

  it("should not notify response if ai_response is nil", function()
    response_handler.notify_response(nil)
    assert.stub(notify.notify).was_not_called()
  end)
end)
