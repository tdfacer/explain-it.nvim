local Morph = require('morph')
local h = Morph.h

local M = {}

--- Status bar component showing current state
---@param ctx morph.Ctx
function M.StatusBar(ctx)
  local state = ctx.props.state

  local status_items = {}

  -- Title
  table.insert(status_items, h.Title({}, ' AI Context Builder '))
  table.insert(status_items, ' | ')

  -- Provider info
  table.insert(status_items, 'Provider: ')
  table.insert(status_items, h.Keyword({}, state.provider or 'none'))
  table.insert(status_items, ' | ')

  -- Context info
  local file_count = state.files and #state.files or 0
  local snippet_count = state.snippets and #state.snippets or 0

  if file_count > 0 or snippet_count > 0 then
    table.insert(status_items, 'Context: ')
    if file_count > 0 then
      table.insert(status_items, h.Number({}, tostring(file_count)))
      table.insert(status_items, ' file' .. (file_count > 1 and 's' or ''))
    end
    if file_count > 0 and snippet_count > 0 then
      table.insert(status_items, ', ')
    end
    if snippet_count > 0 then
      table.insert(status_items, h.Number({}, tostring(snippet_count)))
      table.insert(status_items, ' snippet' .. (snippet_count > 1 and 's' or ''))
    end
    table.insert(status_items, ' | ')
  end

  -- Session info
  if state.session_name then
    table.insert(status_items, 'Session: ')
    table.insert(status_items, h.String({}, state.session_name))
    table.insert(status_items, ' | ')
  end

  -- Status
  if state.loading then
    table.insert(status_items, h.DiagnosticWarn({}, ' Loading... '))
  else
    table.insert(status_items, h.DiagnosticOk({}, ' Ready '))
  end

  -- Keybind hints
  table.insert(status_items, ' | ')
  table.insert(status_items, h.Comment({}, '[f: files, e: export, ?: help]'))

  -- Return the status items directly as content
  -- Don't use virt_lines since it doesn't support morph.nvim tags
  return h('text', { hl = 'StatusLine' }, status_items)
end

return M