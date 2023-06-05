
<p align="center">
  <h1 align="center"><code>expl[AI]n-it.nvim</code></h2>
</p>

<p align="center">
    > Simple and effective AI integration with your favorite Neovim text editor! Ask a question, and let robots <code>expl[AI]n-it</code>!
</p>
  
![](https://github.com/trevordf/gifs/blob/main/explain-it.png)  

## See it in Action

#### Explain Code

<details>
<summary>Visually select a block of text in your buffer, and have ChatGPT tell you what it does! Optionally customize the prompt included in your request.</summary>
  
  ![](https://github.com/trevordf/gifs/blob/main/explain_code.gif)
  
</details>

#### Summarize a Block of Text

<details>
<summary>Sick of reading documents? Have ChatGPT summarize what your buffer says.</summary>
  
  ![](https://github.com/trevordf/gifs/blob/main/summarize.gif)
  
</details>

#### Explain Code ex. 2

<details>
<summary>Have questions on the full buffer? Shortcut to include everything in your request, no visual selection necessary.</summary>
  
  ![](https://github.com/trevordf/gifs/blob/main/explain_code_2.gif)
  
</details>

#### Write Unit Tests
<details>
<summary>Jump start your unit tests by letting ChatGPT take the first crack at writing them for you.</summary>
  
  ![](https://github.com/trevordf/gifs/blob/main/speed_up.gif)
  
</details>

#### Write Code
<details>
<summary>Stub out what you need done, and let ChatGPT fill in the blanks.</summary>
  
  ![](https://github.com/trevordf/gifs/blob/main/write_fibonacci.gif)
  
</details>


## ⚡️ Features

> Neovim integration with the ChatGPT API

- Send your entire buffer to ChatGPT APIs! This will allow you to do things like:
  - Explain what code does
  - Generate code snippets
  - Write unit tests
  - Fetch non-code responses, such as document generation or answering questions
- Keybindings for quick integration with separate models
- Write responses to text files for persistence
- Visual selection is supported to

## 📋 Installation

<div align="left">
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
  use ({
    'tdfacer/explain-it.nvim',
    requires = {
      "rcarriga/nvim-notify",
    },
    config = function ()
      require "explain-it".setup {
        -- Prints useful log messages
        debug = true,
        -- Customize notification window width
        max_notification_width = 20,
        -- Retry API calls
        max_retries = 3,
        -- Customize response text file persistence location
        output_directory = "/tmp/chat_output",
        -- Toggle splitting responses in notification window
        split_responses = false,
        -- Set token limit to prioritize keeping costs low, or increasing quality/length of responses
        token_limit = 2000,
      }
    end
  })
```

</td>
</tr>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
  use ({
    'tdfacer/explain-it.nvim',
    requires = {
      "rcarriga/nvim-notify",
    },
    config = function ()
      require "explain-it".setup {
      -- Prints useful log messages
      debug = true,
      -- Customize notification window width
      max_notification_width = 20,
      -- Retry API calls
      max_retries = 3,
      -- Customize response text file persistence location
      output_directory = "/tmp/chat_output",
      -- Toggle splitting responses in notification window
      split_responses = false,
      -- Set token limit to prioritize keeping costs low, or increasing quality/length of responses
      token_limit = 2000,
      }
    end
  })
```

</td>
</tr>
</tbody>
</table>
</div>

## ☄ Getting started
  
1. Sign up for paid account at https://platform.openai.com/signup
  1. Be sure to note pricing! It is recommended to use something like privacy.com to make sure that you do not accidentally exceed your price limit. Note that there is a separate charge for _ChatGPT_ usage and _API_ usage. We're after _API_.
1. After adding payment info, copy your API key and set it as an environment variable in your shell. Here is a command that will add this to your `.zshrc` file:
    ```
    echo 'export CHAT_GPT_API_KEY=<replace_with_your_key>' >> ~/.zshrc
    ```
1. Install the Plugin using your favorite package manager as described above

## ⚙ Configuration

* Sensible default config values have been set. Customize values using the the standard `setup` function.
* See `M.options` [here]([url](https://github.com/tdfacer/explain-it.nvim/blob/main/lua/explain-it/config.lua#L5)) for a full list of options.

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.  See [CONTRIBUTING.md](./CONTRIBUTING.md).
