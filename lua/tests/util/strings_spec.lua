package.path = package.path
  .. ";../../explain-it/?.lua;../../explain-it/services/?.lua;../../explain-it/util/?.lua"

local testModule = require "lua.explain-it.util.strings"

describe("util.strings", function()
  before_each(function()
    require("explain-it").setup {
      max_notification_width = 54,
    }
  end)

  describe("format_string_with_line_breaks", function()
    it("Should format string with line breaks", function()
      local input = "This is a long string that needs to be formatted with line breaks"
      local expected = "This is a long string that needs to be formatted with\nline breaks"

      local actual = testModule.format_string_with_line_breaks(input)

      assert.equal(expected, actual)
    end)

    it("Should not add line breaks if string is shorter than max width", function()
      local input = "Short string"
      local expected = "Short string"

      local actual = testModule.format_string_with_line_breaks(input)

      assert.equal(expected, actual)
    end)
  end)

  describe("truncate_string", function()
    it("Should truncate string if longer than specified length", function()
      local input = "This is a long string that needs to be truncated"
      local expected = "This is a long string that needs to be truncat..."

      local actual = testModule.truncate_string(input, 46)

      assert.equal(expected, actual)
    end)

    it("Should not truncate string if shorter than specified length", function()
      local input = "Short string"
      local expected = "Short string"

      local actual = testModule.truncate_string(input, 30)

      assert.equal(expected, actual)
    end)
  end)
end)
