local M = {}

-- Store active context builder instances by buffer number
M._instances = {}

-- We need to add the parent morph.nvim directory to the runtime path
-- so we can require the morph module
local morph_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h:h:h:h:h:h")
vim.opt.rtp:prepend(morph_path)

local Morph = require('morph')
local h = Morph.h

-- Load components
local StatusBar = require('explain-it.context-builder.components.status_bar').StatusBar
local ContextEditor = require('explain-it.context-builder.components.context_editor').ContextEditor
local ConversationThread  -- Will be implemented inline for now

--- Main Context Builder component
---@param ctx morph.Ctx
local function ContextBuilder(ctx)
  if ctx.phase == 'mount' then
    ctx.state = {
      -- Context state
      files = {},           -- Full file contents
      snippets = {},        -- Visual selections
      instruction = "",     -- Current instruction

      -- UI state
      active_section = "context",  -- context|instruction|response
      show_files = true,
      show_templates = false,

      -- Session state
      session_name = nil,
      conversation = {},    -- Thread history

      -- Provider state
      provider = _G.ExplainIt.config.context_builder.default_provider or "openai",
      loading = false,
    }

    -- Store reference to this context for external updates
    ctx.props.register_context(ctx)
  end

  local state = ctx.state

  -- Build the UI tree
  local result = {
    h(StatusBar, { state = state }),
    '\n\n',
  }

  -- Context section
  table.insert(result, h.Title({}, '# AI Context Builder'))
  table.insert(result, '\n\n')

  -- Show current context
  table.insert(result, h.Title({}, '## Context'))
  table.insert(result, '\n\n')

  if #state.files == 0 and #state.snippets == 0 then
    table.insert(result, h.Comment({}, 'No context added yet. Press "f" to add files or "s" to add snippets.'))
  else
    table.insert(result, h(ContextEditor, {
      files = state.files,
      snippets = state.snippets,
      on_update = function(files, snippets)
        state.files = files
        state.snippets = snippets
        ctx:update(state)
      end
    }))
  end

  table.insert(result, '\n\n')

  -- Instruction section
  table.insert(result, h.Title({}, '## Instruction'))
  table.insert(result, '\n')

  if state.loading then
    table.insert(result, h.DiagnosticWarn({}, "⟳ Processing... Please wait..."))
    table.insert(result, '\n')
    table.insert(result, h.Comment({}, "The AI is thinking. This may take a few seconds..."))
  else
    -- Show placeholder when empty, actual text otherwise
    if state.instruction == "" then
      table.insert(result, h('text', {
        id = 'instruction-input',
        on_change = function(e)
          -- When user starts typing, replace the placeholder
          if e.text ~= "Type your instruction here..." then
            state.instruction = e.text
          else
            state.instruction = ""
          end
          ctx:update(state)
          e.bubble_up = false
        end,
        hl = state.active_section == 'instruction' and 'Visual' or 'Comment',
      }, "Type your instruction here..."))
    else
      table.insert(result, h('text', {
        id = 'instruction-input',
        on_change = function(e)
          state.instruction = e.text
          ctx:update(state)
          e.bubble_up = false
        end,
        hl = state.active_section == 'instruction' and 'Visual' or nil,
      }, state.instruction))
    end
  end

  table.insert(result, '\n\n')

  -- Conversation thread
  if #state.conversation > 0 then
    table.insert(result, h.Title({}, '## Conversation'))
    table.insert(result, '\n\n')
    table.insert(result, h(ConversationThread, { messages = state.conversation }))
  end

  -- Global keybindings
  return h('text', {
    nmap = {
      ['f'] = function()
        -- Schedule the file selection to avoid textlock issues
        vim.schedule(function()
          -- Get current directory (fallback to cwd if buffer has no file)
          local current_dir = vim.fn.expand("%:p:h")
          if current_dir == "" or not vim.fn.isdirectory(current_dir) then
            current_dir = vim.fn.getcwd()
          end

          -- Try using telescope if available
          local has_telescope, telescope = pcall(require, 'telescope.builtin')
          if has_telescope then
            telescope.find_files({
              prompt_title = "Add File to Context",
              cwd = current_dir,
              attach_mappings = function(prompt_bufnr, map)
                local actions = require('telescope.actions')
                local action_state = require('telescope.actions.state')

                actions.select_default:replace(function()
                  actions.close(prompt_bufnr)
                  local selection = action_state.get_selected_entry()
                  if selection then
                    local filepath = selection.path or selection[1]
                    if filepath then
                      M.add_file(filepath)
                    end
                  end
                end)
                return true
              end,
            })
          else
            -- Fallback to vim.ui.input with schedule
            vim.ui.input({
              prompt = 'File path: ',
              default = current_dir .. '/',
              completion = 'file',
            }, function(file)
              if file and file ~= "" then
                M.add_file(file)
              end
            end)
          end
        end)
        return ''
      end,
      ['s'] = function()
        -- TODO: Add snippet from visual selection
        vim.notify("Snippet selector not implemented yet", vim.log.levels.INFO)
        return ''
      end,
      ['i'] = function()
        -- Focus instruction input by searching for the instruction section
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local instruction_line = nil

        -- Find the line after "## Instruction" header
        for i, line in ipairs(lines) do
          if line:match("^## Instruction") then
            -- The instruction text should be 2 lines after the header (skip blank line)
            if i + 2 <= #lines then
              instruction_line = i + 2
              break
            end
          end
        end

        if instruction_line then
          -- Move cursor to the instruction line
          vim.api.nvim_win_set_cursor(0, {instruction_line, 0})

          -- Schedule the insert mode command to avoid textlock
          vim.schedule(function()
            local line_content = vim.api.nvim_get_current_line()
            -- Check if it's the placeholder
            if line_content == "Type your instruction here..." then
              -- Clear the line first
              vim.api.nvim_set_current_line("")
              -- Then enter insert mode
              vim.cmd('startinsert')
            else
              -- Just enter insert mode at the beginning
              vim.cmd('startinsert')
            end
          end)
        else
          vim.notify("Could not find instruction input", vim.log.levels.WARN)
        end
        return ''
      end,
      ['<CR>'] = function()
        if state.instruction ~= "" and not state.loading then
          -- Execute the provider
          local buf = vim.api.nvim_get_current_buf()
          local instance = M._instances[buf]
          if instance then
            M.execute_context(instance)
          else
            vim.notify("Could not find Context Builder instance", vim.log.levels.ERROR)
          end
        elseif state.instruction == "" then
          vim.notify("Please enter an instruction first", vim.log.levels.WARN)
        end
        return ''
      end,
      ['q'] = function()
        -- Close the context builder
        vim.cmd('bdelete!')
        return ''
      end,
      ['e'] = function()
        -- Export context to clipboard
        M.export_to_clipboard()
        return ''
      end,
      ['?'] = function()
        -- Show help
        vim.notify([[Context Builder Help:
f - Add files to context
s - Add snippets to context
i - Focus instruction input
e - Export context to clipboard
<CR> - Send to AI provider (when instruction is entered)
q - Close Context Builder
? - Show this help

Current provider: ]] .. (state.provider or _G.ExplainIt.config.context_builder.default_provider), vim.log.levels.INFO)
        return ''
      end,
    }
  }, result)
end

-- Inline ConversationThread component (simpler than a separate file)
ConversationThread = function(ctx)
  local result = {}

  for i, msg in ipairs(ctx.props.messages) do
    -- Add timestamp
    local timestamp = os.date("%H:%M:%S", msg.timestamp)

    if msg.role == "user" then
      table.insert(result, h.Title({}, '### You '))
      table.insert(result, h.Comment({}, '[' .. timestamp .. ']'))
    else
      table.insert(result, h.Title({}, '### AI '))
      table.insert(result, h.Comment({}, '[' .. timestamp .. ']'))
    end
    table.insert(result, '\n')

    -- Format the content with proper line breaks
    local lines = vim.split(msg.content, '\n', { plain = true })
    for j, line in ipairs(lines) do
      table.insert(result, line)
      if j < #lines then
        table.insert(result, '\n')
      end
    end

    -- Add separator between messages
    if i < #ctx.props.messages then
      table.insert(result, '\n\n---\n\n')
    else
      table.insert(result, '\n\n')
    end
  end

  return result
end

--- Opens the Context Builder in a new buffer
---@param opts table|nil
function M.open(opts)
  opts = opts or {}

  local config = _G.ExplainIt.config.context_builder.window_config

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "AI Context Builder")

  -- Open in a split
  if config.split == "vertical" then
    vim.cmd('vsplit')
    vim.api.nvim_win_set_width(0, math.floor(vim.o.columns * config.width))
  else
    vim.cmd('split')
  end

  vim.api.nvim_win_set_buf(0, buf)

  -- Set buffer options
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'explain-it-context'

  -- Create context storage
  local context_ref = nil

  -- Mount the Context Builder component
  local renderer = Morph.new(buf)
  renderer:mount(h(ContextBuilder, {
    register_context = function(ctx)
      context_ref = ctx
      M._instances[buf] = {
        buffer = buf,
        context = ctx,
        renderer = renderer
      }
    end
  }, {}))

  -- Set buffer autocmd to clean up on close
  vim.api.nvim_create_autocmd({"BufDelete", "BufWipeout"}, {
    buffer = buf,
    once = true,
    callback = function()
      M._instances[buf] = nil
    end
  })
end

--- Get the active Context Builder instance
---@return table|nil
function M.get_active_instance()
  -- Find first active instance
  for buf, instance in pairs(M._instances) do
    if vim.api.nvim_buf_is_valid(buf) then
      return instance
    end
  end
  return nil
end

--- Switch the provider for the active Context Builder
---@param provider_name string Name of the provider to switch to
---@return boolean success
function M.switch_provider(provider_name)
  local instance = M.get_active_instance()
  if not instance then
    vim.notify("No active Context Builder found", vim.log.levels.WARN)
    return false
  end

  -- Validate provider exists in config
  local provider_config = _G.ExplainIt.config.context_builder.providers[provider_name]
  if not provider_config and provider_name ~= "openai" then
    vim.notify("Provider not configured: " .. provider_name, vim.log.levels.ERROR)
    return false
  end

  -- Update state
  local ctx = instance.context
  local state = ctx.state
  state.provider = provider_name
  ctx:update(state)

  vim.notify("Switched to provider: " .. provider_name, vim.log.levels.INFO)
  return true
end

--- Get list of configured providers
---@return table List of provider names
function M.get_providers()
  local providers = { "openai" }  -- OpenAI is always available
  for name, _ in pairs(_G.ExplainIt.config.context_builder.providers) do
    if name ~= "openai" then
      table.insert(providers, name)
    end
  end
  return providers
end

--- Add a file to the active Context Builder
---@param filepath string Path to the file
---@return boolean success
function M.add_file(filepath)
  local instance = M.get_active_instance()
  if not instance then
    vim.notify("No active Context Builder found. Open one with <leader>bn", vim.log.levels.WARN)
    return false
  end

  -- Validate and normalize file path
  filepath = vim.fn.expand(filepath)  -- Expand ~ and other shortcuts
  filepath = vim.fn.fnamemodify(filepath, ':p')  -- Get absolute path

  -- Check if it's a directory
  if vim.fn.isdirectory(filepath) == 1 then
    vim.notify("Cannot add directory, please select a file: " .. filepath, vim.log.levels.ERROR)
    return false
  end

  -- Check if file exists and is readable
  if vim.fn.filereadable(filepath) ~= 1 then
    vim.notify("File not found or not readable: " .. filepath, vim.log.levels.ERROR)
    return false
  end

  -- Read file content
  local file = io.open(filepath, "r")
  if not file then
    vim.notify("Could not open file: " .. filepath, vim.log.levels.ERROR)
    return false
  end

  local content = file:read("*all")
  file:close()

  -- Check if file is empty
  if not content or content == "" then
    vim.notify("File is empty: " .. filepath, vim.log.levels.WARN)
    return false
  end

  -- Add to context
  local ctx = instance.context
  local state = ctx.state

  -- Check if file already added
  for _, f in ipairs(state.files) do
    if f.path == filepath then
      vim.notify("File already in context: " .. filepath, vim.log.levels.INFO)
      return true
    end
  end

  -- Add file
  table.insert(state.files, {
    path = filepath,
    content = content,
  })

  -- Update the component
  ctx:update(state)

  vim.notify("Added file to context: " .. filepath, vim.log.levels.INFO)
  return true
end

--- Add a snippet to the active Context Builder
---@param filepath string Path to the file
---@param start_line number Start line number
---@param end_line number End line number
---@param content string The snippet content
---@return boolean success
function M.add_snippet(filepath, start_line, end_line, content)
  local instance = M.get_active_instance()
  if not instance then
    vim.notify("No active Context Builder found. Open one with <leader>bn", vim.log.levels.WARN)
    return false
  end

  -- Add to context
  local ctx = instance.context
  local state = ctx.state

  -- Add snippet
  table.insert(state.snippets, {
    path = filepath,
    start_line = start_line,
    end_line = end_line,
    content = content,
  })

  -- Update the component
  ctx:update(state)

  vim.notify(string.format("Added snippet from %s:%d-%d", filepath, start_line, end_line), vim.log.levels.INFO)
  return true
end

--- Export the current context to clipboard
---@return boolean success
function M.export_to_clipboard()
  local instance = M.get_active_instance()
  if not instance then
    vim.notify("No active Context Builder found. Open one with <leader>bn", vim.log.levels.WARN)
    return false
  end

  local ctx = instance.context
  local state = ctx.state

  -- Check if there's any context
  if #state.files == 0 and #state.snippets == 0 then
    vim.notify("No context to export", vim.log.levels.WARN)
    return false
  end

  -- Build the export content
  local lines = {}

  -- Add header
  table.insert(lines, "# AI Context")
  table.insert(lines, "")
  table.insert(lines, "Generated on: " .. os.date("%Y-%m-%d %H:%M:%S"))
  table.insert(lines, "")

  -- Add files section
  if #state.files > 0 then
    table.insert(lines, "## Files")
    table.insert(lines, "")

    for i, file in ipairs(state.files) do
      table.insert(lines, "### " .. file.path)
      table.insert(lines, "")
      table.insert(lines, "```" .. vim.fn.fnamemodify(file.path, ":e"))  -- file extension for syntax highlighting
      table.insert(lines, file.content)
      if not file.content:match("\n$") then
        table.insert(lines, "")  -- Ensure newline before closing ```
      end
      table.insert(lines, "```")
      table.insert(lines, "")
    end
  end

  -- Add snippets section
  if #state.snippets > 0 then
    table.insert(lines, "## Snippets")
    table.insert(lines, "")

    for i, snippet in ipairs(state.snippets) do
      table.insert(lines, "### From " .. snippet.path .. ":" .. snippet.start_line .. "-" .. snippet.end_line)
      table.insert(lines, "")
      table.insert(lines, "```" .. vim.fn.fnamemodify(snippet.path, ":e"))
      table.insert(lines, snippet.content)
      if not snippet.content:match("\n$") then
        table.insert(lines, "")
      end
      table.insert(lines, "```")
      table.insert(lines, "")
    end
  end

  -- Add instruction if present
  if state.instruction and state.instruction ~= "" then
    table.insert(lines, "## Instruction")
    table.insert(lines, "")
    table.insert(lines, state.instruction)
    table.insert(lines, "")
  end

  -- Add conversation history if present
  if #state.conversation > 0 then
    table.insert(lines, "## Conversation History")
    table.insert(lines, "")

    for _, msg in ipairs(state.conversation) do
      local timestamp = os.date("%H:%M:%S", msg.timestamp)
      if msg.role == "user" then
        table.insert(lines, "### You [" .. timestamp .. "]")
        table.insert(lines, "")
        table.insert(lines, msg.content)
      else
        table.insert(lines, "### AI [" .. timestamp .. "]")
        table.insert(lines, "")
        table.insert(lines, msg.content)
      end
      table.insert(lines, "")
    end
  end

  -- Join all lines
  local content = table.concat(lines, "\n")

  -- Copy to clipboard
  vim.fn.setreg("+", content)
  vim.fn.setreg("*", content)  -- Also copy to selection register

  -- Calculate size info
  local file_count = #state.files
  local snippet_count = #state.snippets
  local size_kb = math.floor(#content / 1024)

  vim.notify(string.format("Exported context to clipboard: %d files, %d snippets (%d KB)",
    file_count, snippet_count, size_kb), vim.log.levels.INFO)

  return true
end

--- Build full prompt including context, conversation history, and current instruction
---@param context string The context string (files and snippets)
---@param state table The current state with conversation and instruction
---@return string
function M.build_full_prompt(context, state)
  local lines = {}

  -- Add context first
  table.insert(lines, context)

  -- Add conversation history if exists
  if #state.conversation > 0 then
    table.insert(lines, "\n## Previous Conversation\n")

    for _, msg in ipairs(state.conversation) do
      if msg.role == "user" then
        table.insert(lines, "User: " .. msg.content)
      else
        table.insert(lines, "\nAssistant: " .. msg.content)
      end
      table.insert(lines, "")
    end
  end

  -- Add current instruction
  table.insert(lines, "\n## Current Question\n")
  table.insert(lines, state.instruction)

  return table.concat(lines, "\n")
end

--- Build context string from files and snippets
---@param state table The component state
---@return string context_string
function M.build_context_string(state)
  local lines = {}

  -- Add files
  if #state.files > 0 then
    table.insert(lines, "Files:")
    table.insert(lines, "")

    for _, file in ipairs(state.files) do
      table.insert(lines, "File: " .. file.path)
      table.insert(lines, "```" .. vim.fn.fnamemodify(file.path, ":e"))
      table.insert(lines, file.content)
      if not file.content:match("\n$") then
        table.insert(lines, "")
      end
      table.insert(lines, "```")
      table.insert(lines, "")
    end
  end

  -- Add snippets
  if #state.snippets > 0 then
    table.insert(lines, "Code Snippets:")
    table.insert(lines, "")

    for _, snippet in ipairs(state.snippets) do
      table.insert(lines, "From " .. snippet.path .. ":" .. snippet.start_line .. "-" .. snippet.end_line)
      table.insert(lines, "```" .. vim.fn.fnamemodify(snippet.path, ":e"))
      table.insert(lines, snippet.content)
      if not snippet.content:match("\n$") then
        table.insert(lines, "")
      end
      table.insert(lines, "```")
      table.insert(lines, "")
    end
  end

  return table.concat(lines, "\n")
end

--- Execute the context with the selected provider
---@param instance table The Context Builder instance
function M.execute_context(instance)
  local ctx = instance.context
  local state = ctx.state

  -- Check prerequisites
  if not state.instruction or state.instruction == "" then
    vim.notify("No instruction provided", vim.log.levels.WARN)
    return
  end

  if #state.files == 0 and #state.snippets == 0 then
    vim.notify("No context added. Add files or snippets first.", vim.log.levels.WARN)
    return
  end

  -- Set loading state
  state.loading = true
  ctx:update(state)

  -- Build context string
  local context = M.build_context_string(state)

  -- Get provider
  local provider_name = state.provider or _G.ExplainIt.config.context_builder.default_provider
  local provider_config = _G.ExplainIt.config.context_builder.providers[provider_name]

  if not provider_config then
    vim.notify("Provider not configured: " .. provider_name, vim.log.levels.ERROR)
    state.loading = false
    ctx:update(state)
    return
  end

  -- Build full prompt with conversation history
  local full_prompt = M.build_full_prompt(context, state)

  -- For now, use the existing explain-it mechanism if provider is "openai"
  if provider_name == "openai" then
    -- Use existing OpenAI integration
    local chat_gpt = require("explain-it.services.chat-gpt")
    local response_handler = require("explain-it.handlers.response")

    -- Format for OpenAI
    local escaped = require("explain-it.util.escape").get_escaped_string(full_prompt)
    local joined = string.gsub(escaped, "\n", "\\n")

    -- Handle model override if configured
    local original_model
    if provider_config.model then
      original_model = _G.ExplainIt.config.openai_chat_model
      _G.ExplainIt.config.openai_chat_model = provider_config.model
    end

    -- Call OpenAI asynchronously
    chat_gpt.call_gpt_async(
      joined,
      nil,
      "chat_command",
      function(ai_response)
        -- Success callback
        -- Restore original model if we overrode it
        if original_model then
          _G.ExplainIt.config.openai_chat_model = original_model
        end

        if ai_response and ai_response.response then
          -- Add to conversation
          table.insert(state.conversation, {
            role = "user",
            content = state.instruction,
            timestamp = os.time(),
          })

          table.insert(state.conversation, {
            role = "assistant",
            content = ai_response.response,
            timestamp = os.time(),
          })

          -- Clear instruction
          state.instruction = ""
          state.loading = false
          ctx:update(state)

          vim.notify("Response received from " .. provider_name, vim.log.levels.INFO)
        else
          -- Error occurred
          vim.notify("No response received from " .. provider_name, vim.log.levels.ERROR)
          state.loading = false
          ctx:update(state)
        end
      end,
      function(error)
        -- Error callback
        -- Restore original model if we overrode it
        if original_model then
          _G.ExplainIt.config.openai_chat_model = original_model
        end

        vim.notify("OpenAI API error: " .. error, vim.log.levels.ERROR)
        state.loading = false
        ctx:update(state)
      end
    )
  else
    -- Use CLI provider
    local cli = require("explain-it.context-builder.providers.cli")
    local provider = cli.create_from_config(provider_name, provider_config)

    -- Validate provider
    local valid, err = provider:validate()
    if not valid then
      vim.notify("Provider validation failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
      state.loading = false
      ctx:update(state)
      return
    end

    -- Execute provider with full prompt (passing empty string for instruction since it's included in prompt)
    provider:execute(full_prompt, "", function(success, response)
      vim.schedule(function()
        if success then
          -- Add to conversation
          table.insert(state.conversation, {
            role = "user",
            content = state.instruction,
            timestamp = os.time(),
          })

          table.insert(state.conversation, {
            role = "assistant",
            content = response,
            timestamp = os.time(),
          })

          -- Clear instruction
          state.instruction = ""
          state.loading = false
          ctx:update(state)

          vim.notify("Response received from " .. provider_name, vim.log.levels.INFO)
        else
          vim.notify("Provider error: " .. response, vim.log.levels.ERROR)
          state.loading = false
          ctx:update(state)
        end
      end)
    end)
  end
end

return M