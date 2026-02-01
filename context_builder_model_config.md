# Configuring Different Models for Context Builder

You can now configure different OpenAI models for the Context Builder vs regular explain-it.nvim usage!

## Default Configuration

By default, both use the same model:
```lua
require("explain-it").setup({
  openai_chat_model = "gpt-5",  -- Used for both regular and Context Builder
  -- ...
})
```

## Separate Model for Context Builder

To use a different model specifically for the Context Builder:

```lua
require("explain-it").setup({
  -- Regular explain-it uses this model
  openai_chat_model = "gpt-5",

  -- Context Builder configuration
  context_builder = {
    enabled = true,
    providers = {
      openai = {
        -- Override model for Context Builder only
        model = "gpt-4-turbo-preview",  -- or "gpt-4", "gpt-3.5-turbo", etc.
      },
      -- ... other providers
    },
  },
})
```

## Use Cases

This is useful when you want to:

1. **Use a more powerful model for Context Builder** - Since Context Builder handles larger contexts and conversation history, you might want GPT-4 for it while using GPT-3.5 for quick explanations

2. **Use a cheaper model for simple tasks** - Use GPT-3.5 for regular explain-it tasks but GPT-4 for complex Context Builder conversations

3. **Test different models** - Compare responses between models by switching configuration

## Complete Example

```lua
require("explain-it").setup({
  -- Regular explain-it settings
  debug = true,
  openai_chat_model = "gpt-3.5-turbo",  -- Cheaper, faster for simple tasks
  max_notification_width = 200,
  output_directory = "/tmp/explain_it_output",

  -- Context Builder with different model
  context_builder = {
    enabled = true,
    default_provider = "openai",
    providers = {
      openai = {
        -- Use GPT-4 for Context Builder's complex conversations
        model = "gpt-4",
      },
      -- Other providers...
      aichat = {
        command = "aichat",
        args = { "--no-stream" },
      },
    },
    window_config = {
      split = "vertical",
      width = 0.4,
    },
  },
})
```

## How It Works

When the Context Builder executes:
1. It checks if `providers.openai.model` is configured
2. If yes, it temporarily overrides the global model for that request
3. If no, it uses the default `openai_chat_model`

This ensures backward compatibility while allowing flexibility!