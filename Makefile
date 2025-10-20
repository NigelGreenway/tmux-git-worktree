.PHONY: help install test test-utils test-main shellcheck clean

help:
	@echo "Available targets:"
	@echo "  make install      - Install bats-core and helper libraries"
	@echo "  make test         - Run all tests"
	@echo "  make test-utils   - Run utils.sh tests only"
	@echo "  make test-main    - Run main script tests only"
	@echo "  make clean        - Remove test helper libraries"
	@echo ""
	@echo "Options:"
	@echo "  VERBOSE=1         - Run tests with verbose output"
	@echo ""
	@echo "Examples:"
	@echo "  make test VERBOSE=1"
	@echo "  make test-utils"

install:
	@echo "Installing bats-core..."
	@command -v bats >/dev/null 2>&1 || { \
		echo "bats not found. Installing via npm..."; \
		npm install -g bats; \
	}
	@echo "Installing bats helper libraries..."
	@mkdir -p test/test_helper
	@if [ ! -d "test/test_helper/bats-support" ]; then \
		git clone --depth 1 https://github.com/bats-core/bats-support.git test/test_helper/bats-support; \
	else \
		echo "bats-support already installed"; \
	fi
	@if [ ! -d "test/test_helper/bats-assert" ]; then \
		git clone --depth 1 https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert; \
	else \
		echo "bats-assert already installed"; \
	fi
	@echo "Installation complete!"

test:
	@echo "Running all tests..."
ifdef VERBOSE
	@bats test/*.bats --tap
else
	@bats test/*.bats
endif

test-utils:
	@echo "Running utils.sh tests..."
ifdef VERBOSE
	@bats test/utils.bats --tap
else
	@bats test/utils.bats
endif

test-main:
	@echo "Running main script tests..."
ifdef VERBOSE
	@bats test/main.bats --tap
else
	@bats test/main.bats
endif

clean:
	@echo "Removing test helper libraries..."
	@rm -rf test/test_helper/bats-support
	@rm -rf test/test_helper/bats-assert
	@echo "Cleanup complete!"
