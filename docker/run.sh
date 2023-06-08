#!/usr/bin/env bash

if [[ -z ${CHAT_GPT_API_KEY} ]]; then
  printf '\e[41m%-6s\e[m\n' "Please set CHAT_GPT_API_KEY env var and try again."
  exit 0
fi

docker run \
  -it \
  --rm \
  -e CHAT_GPT_API_KEY="${CHAT_GPT_API_KEY}" \
  explain-it:latest
