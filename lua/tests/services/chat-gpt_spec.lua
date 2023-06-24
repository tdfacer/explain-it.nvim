local mock = require "luassert.mock"
package.path = package.path
  .. ";../../explain-it/?.lua;../../explain-it/services/?.lua;../../explain-it/util/?.lua"

describe("chat-gpt", function()
  local chat_gpt = require "explain-it.services.chat-gpt"
  local file_type = vim.bo.filetype

  before_each(function()
    require("explain-it").setup {
      token_limit = 2000,
      output_directory = ".",
    }
    vim.bo.filetype = file_type
  end)

  -- local chat_gpt = require("../../explain-it.services.chat-gpt")
  -- local string_util = require "explain-it.util.strings"

  it("should format response correctly", function()
    local response_json = {
      choices = {
        {
          text = "This is a response",
        },
      },
    }
    local formatted_response = chat_gpt.format_response(response_json, true)
    assert.are.equal(formatted_response, "This is a response")
  end)

  it("should get filetype correctly", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "lua"
    local filetype = chat_gpt.get_filetype()
    assert.are.equal(filetype, "lua")
    mock.revert(vim_mock)
  end)

  it("should get default question based on filetype", function()
    local question = chat_gpt.get_question "arbitrary question"
    assert.are.equal(question, "arbitrary question")
  end)

  it("should get default question based on filetype", function()
    local question = chat_gpt.get_question ""
    assert.are.equal(question, "what does this code do?")
  end)

  it("should get formatted prompt correctly - no api key", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns ""
    local escaped_prompt = "This is an escaped prompt"
    local question = "What does this code do?"
    ---@type completion_command
    local command_type = "completion_command"
    assert.has_error(function()
      chat_gpt.get_formatted_command(escaped_prompt, question, command_type)
    end, "Failed to get API key. Is CHAT_GPT_API_KEY env var set?")
  end)

  it("should get formatted prompt correctly - chat_command", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns "FAKE KEY"
    local escaped_prompt = "This is an escaped prompt"
    local question = "What does this code do?"
    ---@type chat_command
    local command_type = "chat_command"

    local formatted_prompt = chat_gpt.get_formatted_command(escaped_prompt, question, command_type)
    assert.are.equal(
      formatted_prompt,
      '  curl https://api.openai.com/v1/chat/completions \\\n    2>/dev/null \\\n    -H "Content-Type: application/json" \\\n    -H "Authorization: Bearer FAKE KEY" \\\n    -d \'{\n      "model": "gpt-3.5-turbo-0301",\n      "messages": [{"role": "user", "content": "What does this code do?\\nThis is an escaped prompt"}],\n      "max_tokens": 2000,\n      "temperature": 0.2\n    }\'\n'
    )
  end)

  it("should get formatted prompt correctly - completion_command", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns "FAKE KEY"
    local escaped_prompt = "This is an escaped prompt"
    local question = "What does this code do?"
    ---@type completion_command
    local command_type = "completion_command"

    local formatted_prompt = chat_gpt.get_formatted_command(escaped_prompt, question, command_type)
    assert.are.equal(
      formatted_prompt,
      '  curl https://api.openai.com/v1/completions \\\n    2>/dev/null \\\n    -H "Content-Type: application/json" \\\n    -H "Authorization: Bearer FAKE KEY" \\\n    -d \'{\n      "model": "text-davinci-003",\n      "prompt": "What does this code do?\\nThis is an escaped prompt",\n      "max_tokens": 2000,\n      "temperature": 0\n    }\'\n'
    )
  end)

  it("should call ChatGPT API correctly", function()
    local escaped_input = "This is an escaped input"
    local optional_question = "What does this code do?"
    local prompt_type = "completion_command"
    local response = chat_gpt.call_gpt(escaped_input, optional_question, prompt_type)
    assert.are.equal(type(response), "string")
  end)

  it("should write prompt and response to file correctly", function()
    local prompt = "What does this code do?"
    local response = "This is a response"
    local temp_file = chat_gpt.write_prompt_and_response_to_file(prompt, response)
    local fh, err = io.open(temp_file, "r")
    if err or not fh then
      error "failed to get fh"
    end
    local file_content = fh:read "*all"
    fh:close()
    assert.are.equal(file_content, "What does this code do?\n\n\n\nThis is a response")
  end)
end)
