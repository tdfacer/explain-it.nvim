local M = {}

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
        -- TODO: Open file selector
        vim.notify("File selector not implemented yet", vim.log.levels.INFO)
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

  -- Mount the Context Builder component
  local renderer = Morph.new(buf)
  renderer:mount(h(ContextBuilder, {}, {}))
end

return M