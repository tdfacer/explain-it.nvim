local system = require "explain-it.system"
local stub = require "luassert.stub"

describe("system", function()
  before_each(function()
    require("explain-it").setup {
      output_directory = "/tmp",
    }
  end)

  describe("make_system_call", function()
    it("should return the result of the command", function()
      local result = system.make_system_call "echo 'hello world'"
      assert.are.equal(result, "hello world\n")
    end)

    it("should return '' if the command fails", function()
      local result = system.make_system_call "nonexistent_command"
      assert.are.equal(result, "")
    end)
  end)

  describe("make_system_call_with_retry", function()
    it("should return the result of the command", function()
      ---@type {hello: string}
      local result = system.make_system_call_with_retry 'echo \'{"hello":"world"}\''
      assert.are.equal(result.hello, "world")
    end)

    it("should retry the command if it fails", function()
      assert.has_error(function()
        system.make_system_call_with_retry "echo '{\"error\":truez}'"
      end, "failed to get valid response after 3 retries")
    end)
  end)

  describe("make_temp_file", function()
    it("should return a valid temporary file path", function()
      local temp_file = system.make_temp_file()
      assert.is_string(temp_file)
      assert.are_equal(vim.fn.isdirectory ".", 1)

      -- clean up temporary test file
      system.make_system_call("rm -rf " .. temp_file)
    end)

    it("should throw an error if it fails to create a temporary file", function()
      stub(system, "make_system_call").returns(nil)
      assert.has_error(system.make_temp_file, "failed to create temporary file")
      system.make_system_call:revert()
    end)
  end)
end)
