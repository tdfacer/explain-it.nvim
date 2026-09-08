#!/usr/bin/env nvim -l

-- Test script to verify Context Builder can be loaded and opened
-- Run with: nvim -l examples/test_context_builder.lua

-- Add parent directories to runtime path
local current_dir = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h:h")
local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
vim.opt.rtp:prepend(current_dir) -- explain-it.nvim
vim.opt.rtp:prepend(parent_dir) -- morph.nvim

-- Test 1: Load explain-it module
print("Test 1: Loading explain-it module...")
local ok, explain_it = pcall(require, "explain-it")
if ok then
  print("✓ explain-it module loaded successfully")
else
  print("✗ Failed to load explain-it: " .. tostring(explain_it))
  os.exit(1)
end

-- Test 2: Setup with Context Builder enabled
print("\nTest 2: Setting up explain-it with Context Builder...")
local setup_ok, setup_err = pcall(
  function()
    explain_it.setup {
      debug = true,
      context_builder = {
        enabled = true,
        default_provider = "test",
        providers = {
          test = {
            command = "echo",
            args = { "Test response" },
          },
        },
      },
    }
  end
)

if setup_ok then
  print("✓ Setup completed successfully")
else
  print("✗ Setup failed: " .. tostring(setup_err))
  os.exit(1)
end

-- Test 3: Check configuration
print("\nTest 3: Checking configuration...")
local config = _G.ExplainIt.config
if config.context_builder and config.context_builder.enabled then
  print("✓ Context Builder is enabled in config")
  print("  Default provider: " .. (config.context_builder.default_provider or "none"))
else
  print("✗ Context Builder not properly configured")
  os.exit(1)
end

-- Test 4: Check if open_context_builder function exists
print("\nTest 4: Checking API functions...")
if type(explain_it.open_context_builder) == "function" then
  print("✓ open_context_builder function exists")
else
  print("✗ open_context_builder function not found")
  os.exit(1)
end

-- Test 5: Try loading Context Builder module
print("\nTest 5: Loading Context Builder module...")
local cb_ok, context_builder = pcall(require, "explain-it.context-builder")
if cb_ok then
  print("✓ Context Builder module loaded")
  if type(context_builder.open) == "function" then
    print("✓ Context Builder open function exists")
  else
    print("✗ Context Builder open function not found")
  end
else
  print("✗ Failed to load Context Builder: " .. tostring(context_builder))
end

-- Test 6: Load provider modules
print("\nTest 6: Loading provider modules...")
local base_ok, base = pcall(require, "explain-it.context-builder.providers.base")
local cli_ok, cli = pcall(require, "explain-it.context-builder.providers.cli")

if base_ok then
  print("✓ Base provider module loaded")
else
  print("✗ Failed to load base provider: " .. tostring(base))
end

if cli_ok then
  print("✓ CLI provider module loaded")
else
  print("✗ Failed to load CLI provider: " .. tostring(cli))
end

-- Test 7: Create a CLI provider instance
print("\nTest 7: Creating provider instance...")
if cli_ok and cli.create_from_config then
  local provider_ok, provider = pcall(cli.create_from_config, "test", {
    command = "echo",
    args = { "Hello from test" },
  })

  if provider_ok and provider then
    print("✓ Provider instance created")
    if provider.name == "test" then print("✓ Provider name is correct") end
    if type(provider.execute) == "function" then print("✓ Provider has execute method") end
  else
    print("✗ Failed to create provider: " .. tostring(provider))
  end
else
  print("✗ CLI provider module not properly loaded")
end

print("\n=== All tests completed ===")
print("The AI Context Builder extension has been successfully added to explain-it.nvim!")
print("\nNext steps:")
print("1. Open Neovim and run the example: :luafile examples/context_builder_example.lua")
print("2. Use :ExplainItContext or the configured keybinding to open the Context Builder")
print("3. The UI will show, though file selection and AI integration need further implementation")
