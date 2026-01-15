local Morph = require('morph')
local h = Morph.h

local M = {}

--- Context item component for displaying a file or snippet
---@param ctx morph.Ctx
local function ContextItem(ctx)
  local item = ctx.props.item
  local type = ctx.props.type
  local on_remove = ctx.props.on_remove

  if ctx.phase == 'mount' then
    ctx.state = { expanded = true }
  end

  local state = ctx.state

  local header = {}

  -- Build header
  table.insert(header, h('text', {
    nmap = {
      ['x'] = function()
        on_remove(item)
        return ''
      end,
      ['<Space>'] = function()
        state.expanded = not state.expanded
        ctx:update(state)
        return ''
      end,
    }
  }, {
    state.expanded and '▼ ' or '▶ ',
    type == 'file' and h.Directory({}, item.path) or
    h.String({}, item.path .. ':' .. item.start_line .. '-' .. item.end_line),
    ' ',
    h.Comment({}, '[x to remove, space to toggle]'),
  }))

  -- Build content
  local content = {}
  if state.expanded then
    table.insert(content, '\n')

    -- Show preview of content
    if type == 'file' then
      -- Show first few lines of file
      local preview = item.content:match("^(.-\n.-\n.-\n.-\n.-\n)") or item.content
      local is_truncated = #preview < #item.content
      table.insert(content, h('text', { hl = 'Normal' }, preview))
      if is_truncated then
        table.insert(content, h.Comment({}, '... (truncated)'))
      end
    else
      -- Show snippet content
      table.insert(content, h('text', { hl = 'Normal' }, item.content))
    end
  end

  return {
    header,
    content,
  }
end

--- Main context editor component
---@param ctx morph.Ctx
function M.ContextEditor(ctx)
  local files = ctx.props.files or {}
  local snippets = ctx.props.snippets or {}
  local on_update = ctx.props.on_update

  local result = {}

  -- Helper to remove items
  local function remove_file(file)
    local new_files = {}
    for _, f in ipairs(files) do
      if f ~= file then
        table.insert(new_files, f)
      end
    end
    on_update(new_files, snippets)
  end

  local function remove_snippet(snippet)
    local new_snippets = {}
    for _, s in ipairs(snippets) do
      if s ~= snippet then
        table.insert(new_snippets, s)
      end
    end
    on_update(files, new_snippets)
  end

  -- Show files
  if #files > 0 then
    table.insert(result, h.Title({}, '### Files (' .. #files .. ')'))
    table.insert(result, '\n\n')

    for i, file in ipairs(files) do
      table.insert(result, h(ContextItem, {
        key = 'file-' .. i,
        item = file,
        type = 'file',
        on_remove = remove_file,
      }))
      table.insert(result, '\n')
    end

    table.insert(result, '\n')
  end

  -- Show snippets
  if #snippets > 0 then
    table.insert(result, h.Title({}, '### Snippets (' .. #snippets .. ')'))
    table.insert(result, '\n\n')

    for i, snippet in ipairs(snippets) do
      table.insert(result, h(ContextItem, {
        key = 'snippet-' .. i,
        item = snippet,
        type = 'snippet',
        on_remove = remove_snippet,
      }))
      table.insert(result, '\n')
    end
  end

  -- Show help if empty
  if #files == 0 and #snippets == 0 then
    table.insert(result, h.Comment({}, [[No context added yet.

Press "f" to browse and add files
Press "s" to add snippet from visual selection in another buffer
Press "t" to load a template]]))
  end

  -- Show total size info
  if #files > 0 or #snippets > 0 then
    local total_size = 0
    for _, file in ipairs(files) do
      total_size = total_size + #file.content
    end
    for _, snippet in ipairs(snippets) do
      total_size = total_size + #snippet.content
    end

    table.insert(result, '\n')
    table.insert(result, h.Comment({}, string.format('Total context size: %d characters', total_size)))
  end

  return result
end

return M