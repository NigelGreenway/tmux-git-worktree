.PHONY: build test test-utils test-journeys test-modules shell clean

# Docker configuration
DOCKER_IMAGE_NAME = tmux-git-worktree-test
DOCKER_TAG = latest

help:
	@echo "Available targets:"
	@echo ""
	@echo "Testing (isolated environment with Docker):"
	@echo "  make build         - Build Docker test image"
	@echo "  make test          - Run all tests in Docker"
	@echo "  make test-utils    - Run utils.sh tests in Docker"
	@echo "  make test-modules  - Run fzf_modules tests in Docker"
	@echo "  make test-journeys - Run journey tests in Docker"
	@echo "  make shell         - Run shell in Docker"
	@echo "  make clean         - Remove Docker test image"

build:
	@echo "Building Docker test image..."
	@DOCKER_BUILDKIT=1 docker build --network=host -f Dockerfile.test -t $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .
	@echo "Docker image built successfully!"

test: build
	@echo "Running all tests in Docker..."
ifdef VERBOSE
	@docker run --volume ${PWD}/output.log:/tmp/test_output.log --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/utils.bats test/fzf_modules.bats test/journeys/*.bats --tap
else
	@docker run --volume ${PWD}/output.log:/tmp/test_output.log --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/utils.bats test/fzf_modules.bats test/journeys/*.bats
endif

test-utils: build
	@echo "Running utils.sh tests in Docker..."
ifdef VERBOSE
	@docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/utils.bats --tap
else
	@docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/utils.bats
endif

test-modules: build
	@echo "Running fzf_modules tests in Docker..."
ifdef VERBOSE
	@docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/fzf_modules.bats --tap
else
	@docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/fzf_modules.bats
endif

test-journeys: build
	@echo "Running journey tests in Docker..."
ifdef VERBOSE
	@docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/journeys/*.bats --tap
else
	@docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) bats test/journeys/*.bats
endif

shell: build
	@echo "Opening interactive shell in Docker container..."
	@docker run --rm -it $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) /bin/bash

clean:
	@echo "Removing Docker test image..."
	@docker rmi $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) 2>/dev/null || echo "Image not found"
	@echo "Docker cleanup complete!"
