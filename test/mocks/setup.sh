#!/usr/bin/env bash

# Common setup for all journey tests
setup_journey_test() {
  PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/../.." && pwd )"
  MAIN_SCRIPT="$PROJECT_ROOT/src/git-worktree"

  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"

  # Source all mock libraries
  source "$PROJECT_ROOT/test/mocks/git_mocks.sh"
  source "$PROJECT_ROOT/test/mocks/fzf_mocks.sh"
  source "$PROJECT_ROOT/test/mocks/tmux_mocks.sh"

  # Set TMUX environment
  export TMUX="tmux-session"

  # Default read mock (can be overridden)
  read() { return 0; }
  export -f read
}

teardown_journey_test() {
  rm -rf "$TEST_DIR"
  cleanup_mocks
}

cleanup_mocks() {
  unset -f tmux git fzf read command 2>/dev/null || true
  rm -f /tmp/fzf_* /tmp/git_* /tmp/tmux_* 2>/dev/null || true
}

# Helper to create git repo
init_git_repo() {
  git init
  git config user.email "test@test.com"
  git config user.name "Test User"
  git commit --allow-empty -m "Initial commit"
}

# Helper to create symlinks for sourced files
setup_source_files() {
  ln -s "$PROJECT_ROOT/src/utils.sh" "$TEST_DIR/utils.sh"
  mkdir -p "$TEST_DIR/interface"
  ln -s "$PROJECT_ROOT/src/interface/fzf" "$TEST_DIR/interface/"
  ln -s "$PROJECT_ROOT/src/interface/bash" "$TEST_DIR/interface/"

  # Also link the fzf_modules directory
  mkdir -p "$TEST_DIR/interface/fzf_modules"
  for module in "$PROJECT_ROOT/src/interface/fzf_modules"/*.sh; do
    ln -s "$module" "$TEST_DIR/interface/fzf_modules/"
  done
}
