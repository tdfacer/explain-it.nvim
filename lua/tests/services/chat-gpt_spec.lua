local mock = require("luassert.mock")
package.path = package.path .. ";../../explain-it/?.lua;../../explain-it/services/?.lua;../../explain-it/util/?.lua"

describe("chat-gpt", function()
  local chat_gpt = require("explain-it.services.chat-gpt")
  local system = require("explain-it.system")
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
          content = 'This code sets up a test environment using the Lua testing framework "busted". Specifically, it sets up a "before each" hook that will run before each test case. \n\nWithin this hook, it loads a module called "explain-it" and sets some configuration options for it. This module appears to be related to generating documentation or explanations for code. The "token_limit" option sets a limit on the number of tokens (i.e. individual words or symbols) that can be included in each explanation. The "output_directory" option specifies where the generated documentation should be saved.\n\nFinally, the code sets the filetype of the current buffer in the Vim editor to a value stored in the "file_type" variable. This may be relevant for testing code that depends on specific filetypes or syntax highlighting.',
        },
        finish_reason = "stop",
      },
    },
    usage = {
      prompt_tokens = 61,
      completion_tokens = 161,
      total_tokens = 222,
    },
  }

  before_each(function()
    require("explain-it").setup {
      token_limit = 2000,
      output_directory = ".",
      openai_chat_model = "FAKE_MODEL",
      openai_completion_model = "FAKE_COMPLETION_MODEL",
      default_prompts = {
        ["markdown"] = "Answer this question in the markdown file:",
        ["custom"] = "Answer this custom question:",
      },
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

  it("should join anthropic text blocks and skip thinking blocks", function()
    local response_json = {
      type = "message",
      stop_reason = "end_turn",
      content = {
        { type = "thinking", thinking = "" },
        { type = "text", text = "First part. " },
        { type = "text", text = "Second part." },
      },
    }
    assert.are.equal("First part. Second part.", chat_gpt.parse_response(response_json, false))
  end)

  it("should report an anthropic refusal", function()
    local response_json = {
      type = "message",
      stop_reason = "refusal",
      stop_details = { type = "refusal", category = "cyber" },
      content = {},
    }
    assert.are.equal("Claude declined this request (cyber).", chat_gpt.parse_response(response_json, false))
  end)

  it("should return the anthropic error message", function()
    local response_json = {
      type = "error",
      error = { type = "invalid_request_error", message = "model: not found" },
    }
    assert.are.equal("model: not found", chat_gpt.parse_response(response_json, false))
  end)

  it("should get filetype correctly", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "lua"
    local filetype = chat_gpt.get_filetype()
    assert.are.equal(filetype, "lua")
    mock.revert(vim_mock)
  end)

  it("should get default question based on filetype", function()
    local question = chat_gpt.get_question("arbitrary question")
    assert.are.equal(question, "arbitrary question")
  end)

  it("should get default question based on filetype (markdown)", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "markdown"
    local question = chat_gpt.get_question("")
    assert.are.equal(question, "Answer this question in the markdown file:")
    mock.revert(vim_mock)
  end)

  it("should get default question based on filetype (custom)", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "custom"
    local question = chat_gpt.get_question("")
    assert.are.equal(question, "Answer this custom question:")
    mock.revert(vim_mock)
  end)

  it("should get default question based on filetype (default)", function()
    local vim_mock = mock(vim.bo, true)
    vim_mock.filetype = "lua"
    local question = chat_gpt.get_question("")
    assert.are.equal(question, "What does this code do?")
    mock.revert(vim_mock)
  end)

  it("should error when there is no api key", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns("")
    assert.has_error(
      function() chat_gpt.build_request("some input", "What does this code do?", "completion_command") end,
      "Failed to get API key. Is CHAT_GPT_API_KEY env var set?"
    )
    mock.revert(mock_os)
  end)

  it("should build a chat request", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns("FAKE KEY")

    local request = chat_gpt.build_request("some input", "What does this code do?", "chat_command")
    assert.are.same({
      "curl",
      "--silent",
      "https://api.openai.com/v1/chat/completions",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer FAKE KEY",
      "--data-binary",
      "@-",
    }, request.cmd)
    assert.are.same({
      model = "FAKE_MODEL",
      messages = { { role = "user", content = "What does this code do?\nsome input" } },
      max_completion_tokens = 20000,
    }, vim.json.decode(request.body))
    mock.revert(mock_os)
  end)

  it("should build a completion request", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns("FAKE KEY")

    local request = chat_gpt.build_request("some input", "What does this code do?", "completion_command")
    assert.are.equal("https://api.openai.com/v1/completions", request.cmd[3])
    assert.are.same({
      model = "FAKE_COMPLETION_MODEL",
      prompt = "What does this code do?\nsome input",
      max_tokens = 2000,
    }, vim.json.decode(request.body))
    mock.revert(mock_os)
  end)

  it("should round-trip special characters in the request body", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns("FAKE KEY")

    local input = table.concat({
      [[git describe --long 2>/dev/null \]],
      [[  | sed 's/\([^-]*-g\)/r\1/' \]],
      [[  || printf "r%s.%s" "$(git rev-list --count HEAD)"]],
      "tab:\t cr:\r nul-ish:\1 quote:' dquote:\"",
    }, "\n")
    local request = chat_gpt.build_request(input, "100% safe?", "chat_command")
    assert.are.equal("100% safe?\n" .. input, vim.json.decode(request.body).messages[1].content)
    mock.revert(mock_os)
  end)

  describe("anthropic provider", function()
    before_each(function()
      _G.ExplainIt.config.provider = "anthropic"
      _G.ExplainIt.config.anthropic_model = "claude-opus-5"
      _G.ExplainIt.config.anthropic_fallbacks = "default"
    end)
    after_each(function() _G.ExplainIt.config.provider = "openai" end)

    it("should build a messages request", function()
      local mock_os = mock(os, true)
      mock_os.getenv.returns("FAKE ANTHROPIC KEY")

      local request = chat_gpt.build_request("some input", "What does this code do?", "chat_command")
      assert.are.same({
        "curl",
        "--silent",
        "https://api.anthropic.com/v1/messages",
        "-H",
        "Content-Type: application/json",
        "-H",
        "x-api-key: FAKE ANTHROPIC KEY",
        "-H",
        "anthropic-version: 2023-06-01",
        "-H",
        "anthropic-beta: server-side-fallback-2026-07-01",
        "--data-binary",
        "@-",
      }, request.cmd)
      assert.are.same({
        model = "claude-opus-5",
        max_tokens = 16000,
        messages = { { role = "user", content = "What does this code do?\nsome input" } },
        fallbacks = "default",
      }, vim.json.decode(request.body))
      mock.revert(mock_os)
    end)

    it("should omit fallbacks when disabled", function()
      _G.ExplainIt.config.anthropic_fallbacks = false
      local mock_os = mock(os, true)
      mock_os.getenv.returns("FAKE ANTHROPIC KEY")

      local request = chat_gpt.build_request("some input", "question", "completion_command")
      assert.is_nil(vim.json.decode(request.body).fallbacks)
      assert.is_false(vim.tbl_contains(request.cmd, "anthropic-beta: server-side-fallback-2026-07-01"))
      mock.revert(mock_os)
    end)

    it("should error when ANTHROPIC_API_KEY is missing", function()
      local mock_os = mock(os, true)
      mock_os.getenv.returns("")
      assert.has_error(
        function() chat_gpt.build_request("input", "question", "chat_command") end,
        "Failed to get API key. Is ANTHROPIC_API_KEY env var set?"
      )
      mock.revert(mock_os)
    end)
  end)

  it("should call ChatGPT API correctly", function()
    local mock_os = mock(os, true)
    mock_os.getenv.returns("FAKE KEYZUS")

    local mock_system = mock(system, true)
    mock_system.make_system_call_with_retry.returns(example_response)
    local input = "This is an input"
    local optional_question = "What does this code do?"
    local prompt_type = "completion_command"
    local response = chat_gpt.call_gpt(input, optional_question, prompt_type)
    assert.are.equal(type(response), "table")
    local call_args = mock_system.make_system_call_with_retry.calls[1].vals
    assert.are.equal("curl", call_args[1][1])
    assert.are.equal("What does this code do?\nThis is an input", vim.json.decode(call_args[2]).prompt)
    mock.revert(mock_os)
    mock.revert(mock_system)
  end)

  it("should write prompt and response to file correctly", function()
    local ai_response = {
      question = "some question",
      input = "some input",
      response = "some response",
    }
    local temp_file = chat_gpt.write_ai_response_to_file(ai_response)
    local fh, err = io.open(temp_file, "r")
    if err or not fh then error("failed to get fh") end
    local file_content = fh:read("*all")
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
