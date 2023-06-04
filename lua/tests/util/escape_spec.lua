package.path = package.path
  .. ";../../explain-it/?.lua;../../explain-it/services/?.lua;../../explain-it/util/?.lua"

local escape = require "explain-it.util.escape"

describe("escape", function()
  it("should escape double quotes", function()
    local input = 'This "string" contains double quotes'
    local expected_output = 'This \\"string\\" contains double quotes'
    assert.are.equal(expected_output, escape.escape(input))
  end)

  it("should escape single quotes", function()
    local input = "This 'string' contains single quotes"
    local expected_output = "This '\\''string'\\'' contains single quotes"
    assert.are.equal(expected_output, escape.escape(input))
  end)

  it("should escape tabs", function()
    local input = "This\tstring\tcontains\ttabs"
    local expected_output = "This  string  contains  tabs"
    assert.are.equal(expected_output, escape.escape(input))
  end)
end)

describe("get_escaped_string", function()
  it("should escape a string value", function()
    local input = "This string contains double quotes \" and single quotes '"
    local expected_output = "This string contains double quotes \\\" and single quotes '\\''"
    assert.are.equal(expected_output, escape.get_escaped_string(input))
  end)

  it("should escape all string values in a table", function()
    local input = {
      "This string contains double quotes \" and single quotes '",
      "This string contains a tab\t",
    }
    local expected_output =
      "This string contains double quotes \\\" and single quotes '\\''\\nThis string contains a tab  "
    assert.are.equal(expected_output, escape.get_escaped_string(input))
  end)

  it("should return the input if it's not a string or table", function()
    local input = 123
    ---@diagnostic disable-next-line: param-type-mismatch
    assert.are.equal(tostring(input), escape.get_escaped_string(input))
  end)
end)
