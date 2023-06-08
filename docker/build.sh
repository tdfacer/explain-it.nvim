#!/usr/bin/env bash

docker build --tag explain-it:latest --label explain-it .
docker image prune --force --filter='label=explain-it'
