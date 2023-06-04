# we disable the `all` command because some external tool might run it automatically
.SUFFIXES:

all:

run:
	nvim --cmd "set rtp+=./" --cmd 'lua require("explain-it").setup()' -o lua/explain-it/init.lua

# runs unit tests
# test:
# 	nvim --cmd "set rtp+=./" --headless -c 'lua require("explain-it").setup()' -c "PlenaryBustedDirectory lua/tests/"

test:
	nvim --version | head -n 1 && echo ''
	nvim --headless \
		-c "set rtp+=./" \
		-c "set rtp+=./deps/nvim-notify" \
		-c "set rtp+=./deps/plenary.nvim" \
		-c "PlenaryBustedDirectory lua/tests/"
		# --noplugin \
		# -c 'lua require("explain-it").setup()' \

# runs all the test files.
test-old:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 1 }) } })"

# installs `mini.nvim`, used for both the tests and documentation.
deps:
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim
	git clone --depth 1 https://github.com/rcarriga/nvim-notify deps/nvim-notify
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim deps/plenary.nvim

# installs deps before running tests, useful for the CI.
test-ci: deps test

# generates the documentation.
documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

# installs deps before running the documentation generation, useful for the CI.
documentation-ci: deps documentation

# performs a lint check and fixes issue if possible, following the config in `stylua.toml`.
lint:
	stylua .

# setup
setup:
	./scripts/setup.sh
