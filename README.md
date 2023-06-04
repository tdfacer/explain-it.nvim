<p align="center">
  <h1 align="center">explain-it.nvim</h2>
</p>

<p align="center">
    > A catch phrase that describes your plugin.
</p>

<div align="center">
    > Drag your video (<10MB) here to host it for free on GitHub.
</div>

<div align="center">

> Videos don't work on GitHub mobile, so a GIF alternative can help users.

_[GIF version of the showcase video for mobile users](SHOWCASE_GIF_LINK)_

</div>

## Initial Setup

* Sign up for paid account at https://platform.openai.com/signup
* Be sure to note pricing! It is recommended to use something like privacy.com to make sure that you do not accidentally exceed your price limit.

## OpenAI API Reference

* [chat](https://platform.openai.com/docs/api-reference/chat)
* [completions](https://platform.openai.com/docs/api-reference/completions)
* [models](https://platform.openai.com/docs/api-reference/models)

## OpenAI Documentation

* [models](https://platform.openai.com/docs/models/overview)

## Adding New Models

* Identify the model name with a request to `GET https://api.openai.com/v1/models`
* Make sure the model supports the API you're interested in using (see Model endpoint compatibility [here](https://platform.openai.com/docs/models/model-endpoint-compatibility))
* Modify the `command`, currently in `./lua/explain-it/services/chat-gpt.lua`, to use the model of interest
* Make sure you are parsing the response correctly (should work out of the box if you are using the `chat` or `completions` APIs)

## ⚡️ Features

> Write short sentences describing your plugin features

- FEATURE 1
- FEATURE ..
- FEATURE N

## 📋 Installation

<div align="center">
<table>
<thead>
<tr>
<th>Package manager</th>
<th>Snippet</th>
</tr>
</thead>
<tbody>
<tr>
<td>

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

</td>
<td>

```lua
-- stable version
use {"explain-it.nvim", tag = "*" }
-- dev version
use {"explain-it.nvim"}
```

</td>
</tr>
<tr>
<td>

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

</td>
<td>

```lua
-- stable version
Plug "explain-it.nvim", { "tag": "*" }
-- dev version
Plug "explain-it.nvim"
```

</td>
</tr>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
-- stable version
require("lazy").setup({{"explain-it.nvim", version = "*"}})
-- dev version
require("lazy").setup({"explain-it.nvim"})
```

</td>
</tr>
</tbody>
</table>
</div>

## ☄ Getting started

> Describe how to use the plugin the simplest way

## ⚙ Configuration

> The configuration list sometimes become cumbersome, making it folded by default reduce the noise of the README file.

<details>
<summary>Click to unfold the full list of options with their default values</summary>

> **Note**: The options are also available in Neovim by calling `:h explain-it.options`

</details>

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|  `:Toggle`  |     Enables the plugin.    |

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 🗞 Wiki

You can find guides and showcase of the plugin on [the Wiki](https://github.com/trevor/explain-it.nvim/wiki)

## 🎭 Motivations

> If alternatives of your plugin exist, you can provide some pros/cons of using yours over the others.

## Contributing

* See [CONTRIBUTING.md](./CONTRIBUTING.md)
* Make sure all functions include [annotations](https://github.com/LuaLS/lua-language-server/wiki/Annotations)
* Good test examples [here](https://github.com/terrortylor/neovim-environment/blob/045830ffd6ec19b280834fb4ecbdd8f6b36849ba/lua/spec/util/buffer_spec.lua)

* Mocks

```
local stub = require "luassert.stub"
    stub(vim.ui, "input")
      vim.print("### vim.ui.input")
      for k, _ in pairs(vim.ui.input) do
        print("### key: " .. k)
      end

### vim.ui.input
### key: calls
### key: returnvals
### key: returns
### key: by_default
### key: target_table
### key: target_key
### key: called
### key: called_with
### key: clear
### key: returned_with
### key: on_call_with
### key: invokes
### key: revert
### key: callback
```
