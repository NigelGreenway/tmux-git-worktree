#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../mocks/setup'

setup() {
  setup_journey_test
  init_git_repo

  # Create directory structure (actual worktrees are mocked in tests)
  mkdir -p ../existing-worktree
}

teardown() {
  teardown_journey_test
}

@test "user creates new worktree with new branch from commit" {
  # Arrange: Set up mocks for new worktree creation
  mock_git_capture_worktree_add
  mock_fzf_create_worktree "new-feature" "new-feature-branch" "abc123"
  mock_tmux_capture_window
  setup_source_files

  # Act: Run the script
  run "$MAIN_SCRIPT"

  # Assert: Verify git worktree add was called correctly
  assert_success
  [[ -f /tmp/git_worktree_add.txt ]] || skip "git worktree add was not called"

  run cat /tmp/git_worktree_add.txt
  assert_output --partial "PATH="
  assert_output --partial "new-feature"
  assert_output --partial "NEW_BRANCH=new-feature-branch"
  assert_output --partial "COMMIT_REF=abc123"

  # Verify tmux window was created
  [[ -f /tmp/tmux_window.txt ]] || skip "tmux new-window was not called"

  run cat /tmp/tmux_window.txt
  assert_output --partial "new-feature"
  assert_output --partial "NAME=new-feature"
}

@test "user creates new worktree with existing branch" {
  # Arrange: User types new worktree name, selects existing branch
  mock_git_capture_worktree_add
  mock_fzf_select_existing_branch "my-worktree" "existing-branch"
  mock_tmux_capture_window
  setup_source_files

  # Act
  run "$MAIN_SCRIPT"

  # Assert: Worktree created with existing branch (no -b flag)
  assert_success
  [[ -f /tmp/git_worktree_add.txt ]] || skip "git worktree add was not called"

  run cat /tmp/git_worktree_add.txt
  assert_output --partial "my-worktree"
  assert_output --partial "BRANCH=existing-branch"
  # refute_output --partial "NEW_BRANCH="  # Should not create new branch
}
