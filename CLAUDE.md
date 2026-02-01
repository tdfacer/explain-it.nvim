# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

explain-it.nvim is a Neovim plugin that integrates AI capabilities (primarily OpenAI API) directly into the editor. Users can explain code, summarize text, generate code, and write unit tests. The plugin includes a newer "Context Builder" feature that provides an interactive UI for complex AI interactions.

## Development Commands

```bash
make run          # Run Neovim with minimal config for testing local changes
make test         # Run Busted test suite (requires deps)
make deps         # Clone test dependencies (mini.nvim, plenary, nvim-notify)
make lint         # Format code with stylua
make documentation # Generate docs with mini.doc
make docker       # Build and run in Docker container
```

View current settings in Neovim: `:lua =ExplainIt.config`

## Architecture

### Core Module Structure

```
lua/explain-it/
├── init.lua              # Main API: setup(), explain_it(), call_chat_gpt()
├── config.lua            # Configuration system with defaults
├── system.lua            # System calls (sync and async via jobstart)
├── services/chat-gpt.lua # OpenAI API integration, command building, response parsing
├── handlers/response.lua # Notification and buffer output handling
├── util/
│   ├── buffer.lua        # get_visual_selection(), get_buffer_lines()
│   ├── strings.lua       # String formatting utilities
│   ├── debug.lua         # log(), log_always(), tprint()
│   └── escape.lua        # Text escaping for API calls
└── context-builder/      # Interactive UI feature (uses morph.nvim)
    ├── init.lua          # Main component with state management
    ├── components/       # UI components (status_bar, context_editor)
    └── providers/        # AI provider abstractions (base, cli)
```

### Request Flow

1. User triggers `explain_it(opts)` via keybinding
2. Buffer content extracted (full buffer or visual selection)
3. Text escaped and passed to `call_chat_gpt()`
4. `chat_gpt.call_gpt()` builds curl command and makes system call
5. Response parsed and displayed via `response_handler.notify_response()`

### Global State

The plugin uses `_G.ExplainIt` for global state and exposes:
- `_G.ExplainIt.config` - Active configuration after setup()

## Code Conventions

- **Lua annotations**: All functions must include [LuaLS annotations](https://github.com/LuaLS/lua-language-server/wiki/Annotations)
- **Formatting**: stylua with 2-space indent, 100 column width, `no_call_parentheses = true`
- **Debug logging**: Use `D.log(module, format, ...)` for debug output, `D.log_always()` for always-visible logs
- **Testing**: Busted framework via PlenaryBustedDirectory, tests in `lua/tests/`

## Environment Variables

- `CHAT_GPT_API_KEY` - Required for OpenAI API calls

## Context Builder (Opt-in Feature)

The Context Builder provides a React-like UI (morph.nvim) for managing multi-file context and multi-turn conversations. Enable with `context_builder.enabled = true` in setup(). Supports multiple CLI providers (aichat, llm, ollama, anthropic-cli).
