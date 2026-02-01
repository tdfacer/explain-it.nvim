-- AI Context Builder Keymaps for explain-it.nvim
-- Add these to your trevor.keymaps configuration

local opts = { noremap = true, silent = true }

-- Main Context Builder keybinding
-- Using <space>c since it follows your pattern and 'c' for Context
vim.keymap.set(
  "n",
  "<space>c",
  function() require("explain-it").open_context_builder() end,
  { noremap = true, silent = true, desc = "Open AI Context Builder" }
)

-- Alternative with <leader>cb (context builder)
vim.keymap.set(
  "n",
  "<leader>cb",
  function() require("explain-it").open_context_builder() end,
  { noremap = true, silent = true, desc = "Open AI Context Builder" }
)

-- Add current file to context (when Context Builder is already open)
vim.keymap.set("n", "<space>cf", function()
  -- This will be implemented to add current file to open Context Builder
  local current_file = vim.fn.expand("%:p")
  if current_file ~= "" then
    -- TODO: Send event to Context Builder to add file
    vim.notify("Add file to context: " .. current_file .. " (Not fully implemented)", vim.log.levels.INFO)
  end
end, { noremap = true, silent = true, desc = "Add current file to AI context" })

-- Add visual selection to context
vim.keymap.set("v", "<space>cs", function()
  -- Get visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local file = vim.fn.expand("%:p")

  -- TODO: Send to Context Builder
  vim.notify(
    string.format("Add snippet from %s:%d-%d to context (Not fully implemented)", file, start_pos[2], end_pos[2]),
    vim.log.levels.INFO
  )
end, { noremap = true, silent = true, desc = "Add selection to AI context" })

-- Context Builder with template
vim.keymap.set(
  "n",
  "<space>cr",
  function() require("explain-it").open_context_builder { template = "code_review" } end,
  { noremap = true, silent = true, desc = "Open Context Builder with code review template" }
)

vim.keymap.set(
  "n",
  "<space>cd",
  function() require("explain-it").open_context_builder { template = "debugging" } end,
  { noremap = true, silent = true, desc = "Open Context Builder with debugging template" }
)

-- Session management commands
vim.api.nvim_create_user_command("CBSession", function(args)
  local parts = vim.split(args.args, " ")
  local cmd = parts[1]
  local name = parts[2]

  if cmd == "save" and name then
    vim.notify("Save context session: " .. name, vim.log.levels.INFO)
    -- TODO: Implement session save
  elseif cmd == "load" and name then
    vim.notify("Load context session: " .. name, vim.log.levels.INFO)
    -- TODO: Implement session load
  elseif cmd == "list" then
    vim.notify("List context sessions", vim.log.levels.INFO)
    -- TODO: Implement session list
  else
    vim.notify("Usage: CBSession <save|load|list> [name]", vim.log.levels.ERROR)
  end
end, {
  nargs = "+",
  complete = function(arg_lead, cmd_line, cursor_pos)
    local parts = vim.split(cmd_line, " ")
    if #parts == 2 then return { "save", "load", "list" } end
    return {}
  end,
  desc = "Manage AI Context Builder sessions",
})

-- Quick session access
vim.keymap.set("n", "<leader>cs", ":CBSession save ", { noremap = true, desc = "Save context session" })
vim.keymap.set("n", "<leader>cl", ":CBSession load ", { noremap = true, desc = "Load context session" })
vim.keymap.set(
  "n",
  "<leader>cL",
  ":CBSession list<CR>",
  { noremap = true, silent = true, desc = "List context sessions" }
)

-- Provider switching (if you want quick access to different AI providers)
vim.keymap.set("n", "<space>cp", function()
  -- Could open a picker to select provider
  vim.ui.select({ "openai", "aichat", "llm", "ollama" }, { prompt = "Select AI Provider:" }, function(choice)
    if choice then
      -- TODO: Switch provider in Context Builder
      vim.notify("Switch to provider: " .. choice, vim.log.levels.INFO)
    end
  end)
end, { noremap = true, silent = true, desc = "Switch AI provider" })

-- Export context to clipboard
vim.keymap.set("n", "<space>ce", function()
  -- TODO: Export current context to clipboard
  vim.notify("Export context to clipboard (Not implemented)", vim.log.levels.INFO)
end, { noremap = true, silent = true, desc = "Export AI context to clipboard" })

-- Summary of new keybindings:
-- <space>c       - Open AI Context Builder
-- <leader>cb     - Open AI Context Builder (alternative)
-- <space>cf      - Add current file to context
-- <space>cs      - Add visual selection to context (visual mode)
-- <space>cr      - Open with code review template
-- <space>cd      - Open with debugging template
-- <space>cp      - Switch AI provider
-- <space>ce      - Export context to clipboard
-- <leader>cs     - Save context session
-- <leader>cl     - Load context session
-- <leader>cL     - List context sessions
-- :CBSession     - Session management command

-- These keybindings follow your patterns:
-- - <space>* for quick actions
-- - <leader>* for more complex commands
-- - Mnemonic: 'c' for Context, 'f' for File, 's' for Snippet/Save, etc.
-- - No conflicts with your existing keymaps
