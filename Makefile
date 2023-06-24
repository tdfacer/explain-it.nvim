# we disable the `all` command because some external tool might run it automatically
.SUFFIXES:
SHELL := /bin/bash

all:

# run with minimal config
run:
	export XDG_CONFIG_HOME=""; \
	export XDG_DATA_HOME=""; \
	nvim \
	--clean \
		-u "./scripts/test_init.lua" \
		-c 'lua require("explain-it").setup({ debug = true, token_limit = 500, output_directory = "/tmp/explain_it_dev" })' \
		-o lua/explain-it/init.lua

test: deps
	nvim --version | head -n 1 && echo ''
	export XDG_CONFIG_HOME=""; \
	export XDG_DATA_HOME=""; \
	nvim \
	--headless \
	--clean \
		-u "./scripts/test_init.lua" \
		-c "PlenaryBustedDirectory ./lua/tests/ { minimal_init = './scripts/test_init.lua' }"

# installs `mini.nvim`, used for both the tests and documentation.
deps:
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim
	git clone --depth 1 https://github.com/rcarriga/nvim-notify deps/nvim-notify
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim deps/plenary.nvim

# installs deps before running tests, useful for the CI.
test-ci: test

# generates the documentation.
documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

# installs deps before running the documentation generation, useful for the CI.
documentation-ci: deps documentation

# performs a lint check and fixes issue if possible, following the config in `stylua.toml`.
lint:
	stylua .

# docker build
docker-build:
	cd docker; ./build.sh

# docker run
docker-run:
	./docker/run.sh

# docker build and run
docker: docker-build docker-run

# setup
setup:
	./scripts/setup.sh
