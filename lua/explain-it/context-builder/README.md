# AI Context Builder

An interactive UI for building and managing AI context using morph.nvim's React-like component framework.

## Features

- **Interactive Context Management**: Build context by adding files and code snippets
- **Multi-Provider Support**: Works with any CLI-based AI tool (OpenAI, AIChat, LLM, Ollama, etc.)
- **Session Management**: Save and load context sessions in Git-friendly markdown format
- **Conversation Threads**: Maintain conversation history with follow-up questions
- **Context Templates**: Pre-defined templates for common tasks

## Architecture

```
context-builder/
├── init.lua                      # Main Context Builder component and UI
├── components/
│   ├── context_editor.lua        # Manages files and snippets display
│   ├── status_bar.lua            # Status information display
│   ├── file_selector.lua         # (TODO) File browser component
│   ├── snippet_manager.lua       # (TODO) Visual selection manager
│   ├── conversation_thread.lua   # (TODO) Chat history component
│   └── template_picker.lua       # (TODO) Template selection
├── providers/
│   ├── base.lua                  # Abstract provider interface
│   ├── cli.lua                   # Generic CLI tool adapter
│   ├── openai.lua                # (TODO) OpenAI specific adapter
│   └── registry.lua              # (TODO) Provider registration
├── session/
│   ├── manager.lua               # (TODO) Save/load sessions
│   ├── format.lua                # (TODO) Markdown serialization
│   └── templates.lua             # (TODO) Built-in templates
└── utils/
    ├── export.lua                # (TODO) Export functionality
    └── selection.lua             # (TODO) Smart code selection
```

## Usage

### Basic Setup

```lua
require("explain-it").setup({
  context_builder = {
    enabled = true,
    default_provider = "aichat",
    providers = {
      aichat = {
        command = "aichat",
        args = { "--no-stream" },
      },
    },
  },
})
```

### Opening the Context Builder

```lua
require("explain-it").open_context_builder()
```

### Key Bindings (in Context Builder)

- `f` - Add files to context
- `s` - Add snippets from visual selection
- `<CR>` - Send instruction to AI
- `q` - Close Context Builder
- `?` - Show help

## Provider Configuration

Providers are configured in the `context_builder.providers` table:

```lua
providers = {
  my_tool = {
    command = "my-ai-cli",
    args = { "--format", "json" },
    streaming = false,
    format_input = function(context, instruction)
      -- Format the input for your CLI tool
      return context .. "\n\n" .. instruction
    end,
    parse_response = function(output)
      -- Parse the CLI tool's output
      return output
    end,
  },
}
```

## Session Format

Sessions are saved in markdown format for easy version control:

```markdown
---
session: "project-analysis"
created: 2024-01-14T10:30:00Z
provider: aichat
---

# Context

## Files
### `/path/to/file.lua`
```lua
-- File content
```

## Snippets
### From `/path/to/file.lua:10-20`
```lua
-- Snippet content
```

# Conversation

## User [timestamp]
Instruction here

## AI [timestamp]
Response here
```

## Current Status

### Implemented
- ✅ Core Context Builder UI with morph.nvim
- ✅ Basic context editor component
- ✅ Status bar component
- ✅ Provider base interface
- ✅ CLI provider adapter
- ✅ Configuration system
- ✅ Basic keybinding structure

### TODO
- [ ] File selector component (browse and select files)
- [ ] Snippet manager (capture visual selections)
- [ ] Session save/load functionality
- [ ] Template system
- [ ] Export functionality
- [ ] Provider registry and validation
- [ ] Streaming response support
- [ ] Conversation thread UI
- [ ] Smart code selection utilities

## Next Steps

1. Implement file selector using morph.nvim's filetree pattern
2. Add visual selection capture functionality
3. Implement session persistence
4. Add template support
5. Create provider registry for dynamic provider loading
6. Add export options (clipboard, file, share)
7. Implement conversation thread management