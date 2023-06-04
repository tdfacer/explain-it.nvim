# CONTRIBUTING.md

## Annotations

* Make sure all functions include [annotations](https://github.com/LuaLS/lua-language-server/wiki/Annotations)

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
