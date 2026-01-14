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

  table.insert(result, h('text', {
    id = 'instruction-input',
    on_change = function(e)
      state.instruction = e.text
      ctx:update(state)
      e.bubble_up = false
    end,
    hl = state.active_section == 'instruction' and 'Visual' or nil,
  }, state.instruction == "" and "Type your instruction here..." or state.instruction))

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
      ['<CR>'] = function()
        if state.instruction ~= "" and not state.loading then
          -- TODO: Send to provider
          vim.notify("Sending: " .. state.instruction, vim.log.levels.INFO)
        end
        return ''
      end,
      ['q'] = function()
        -- Close the context builder
        vim.cmd('bdelete!')
        return ''
      end,
      ['?'] = function()
        -- Show help
        vim.notify([[Context Builder Help:
f - Add files to context
s - Add snippets to context
<CR> - Send instruction to AI
q - Close Context Builder
? - Show this help]], vim.log.levels.INFO)
        return ''
      end,
    }
  }, result)
end

-- Inline ConversationThread component (simpler than a separate file)
ConversationThread = function(ctx)
  local result = {}

  for _, msg in ipairs(ctx.props.messages) do
    if msg.role == "user" then
      table.insert(result, h.Title({}, '### You'))
    else
      table.insert(result, h.Title({}, '### AI'))
    end
    table.insert(result, '\n')
    table.insert(result, msg.content)
    table.insert(result, '\n\n')
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

return M