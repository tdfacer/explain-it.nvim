local mock = require "luassert.mock"
package.path = package.path
  .. ";../../explain-it/?.lua;../../explain-it/services/?.lua;../../explain-it/util/?.lua"

describe("chat-gpt", function()
  local chat_gpt = require "explain-it.services.chat-gpt"
  local system = require "explain-it.system"
  local file_type = vim.bo.filetype

  local example_response = {
    id = "chatcmpl-7UxZTPAoyikcM4fW1ZLJjRBYUyPlq",
    object = "chat.completion",
    created = 1687613187,
    model = "gpt-3.5-turbo-0301",
    choices = {
      {
        index = 0,
        message = {
          role = "assistant",
          content = "This code sets up a test environment using the Lua testing framework \"busted\". Specifically, it sets up a \"before each\" hook that will run before each test case. \n\nWithin this hook, it loads a module called \"explain-it\" and sets some configuration options for it. This module appears to be related to generating documentation or explanations for code. The \"token_limit\" option sets a limit on the number of tokens (i.e. individual words or symbols) that can be included in each explanation. The \"output_directory\" option specifies where the generated documentation should be saved.\n\nFinally, the code sets the filetype of the current buffer in the Vim editor to a value stored in the \"file_type\" variable. This may be relevant for testing code that depends on specific filetypes or syntax highlighting."
        },
        finish_reason = "stop"
      }
    },
    usage = {
      prompt_tokens = 61,
      completion_tokens = 161,
      total_tokens = 222
    }
  }

  before_each(function()
    require("explain-it").setup {
      token_limit = 2000,
      output_directory = ".",
      default_prompts = {
        ["markdown"] = "Answer this question in the markdown file:",
        ["custom"] = "Answer this custom question:",
      }
    }
    vim.bo.filetype = file_type
  end)

  it("should format response correctly", function()
    local response_json = {
      choices = {
        {
          text = "This is a response",
        },
      },
    }
    local formatted_response = chat_gpt.parse_response(response_json, true)
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

  it("should get default question based on filetype (markdown)", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "markdown"
    local question = chat_gpt.get_question ""
    assert.are.equal(question, "Answer this question in the markdown file:")
    mock.revert(vim_mock)
  end)

  it("should get default question based on filetype (custom)", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "custom"
    local question = chat_gpt.get_question ""
    assert.are.equal(question, "Answer this custom question:")
    mock.revert(vim_mock)
  end)

  it("should get default question based on filetype (default)", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "lua"
    local question = chat_gpt.get_question ""
    assert.are.equal(question, "What does this code do?")
    mock.revert(vim_mock)
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
    mock.revert(mock_os)
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
    mock.revert(mock_os)
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
    mock.revert(mock_os)
  end)

  it("should call ChatGPT API correctly", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns "FAKE KEYZUS"

    local mock_system = mock(system, true)
    mock_system.make_system_call_with_retry.returns(example_response)
    local escaped_input = "This is an escaped input"
    local optional_question = "What does this code do?"
    local prompt_type = "completion_command"
    local response = chat_gpt.call_gpt(escaped_input, optional_question, prompt_type)
    assert.are.equal(type(response), "table")
    mock.revert(mock_os)
    mock.revert(mock_system)
  end)

  it("should write prompt and response to file correctly", function()
    local ai_response = {
      question = "some question",
      input = "some input",
      response = "some response"
    }
    local temp_file = chat_gpt.write_ai_response_to_file(ai_response)
    local fh, err = io.open(temp_file, "r")
    if err or not fh then
      error "failed to get fh"
    end
    local file_content = fh:read "*all"
    fh:close()
    local expected = [[## Question:
some question

## Input:
some input

## Response:
some response]]
    -- assert.are.equal(file_content, "What does this code do?\n\n\n\nThis is a response")
    assert.are.equal(file_content, expected)

    -- clean up temporary test file
    system.make_system_call("rm -rf " .. temp_file)
  end)
end)
