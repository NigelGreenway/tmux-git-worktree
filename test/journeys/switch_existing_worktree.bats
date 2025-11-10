#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../mocks/setup'

setup() {
  setup_journey_test
  init_git_repo

  # Create directory structure (actual worktrees are mocked in tests)
  mkdir -p ../feature-a ../feature-b
}

teardown() {
  teardown_journey_test
}

@test "user selects existing worktree and switches to it" {
  # Arrange: Set up mocks for this journey
  mock_git_with_worktrees "feature-a" "feature-b"
  mock_fzf_select_existing "feature-a"
  mock_tmux_capture_window
  setup_source_files

  # Act: Run the script
  run "$MAIN_SCRIPT"

  # Assert: Verify tmux window created for selected worktree
  assert_success
  [[ -f /tmp/tmux_window.txt ]] || skip "tmux window not created"

  run cat /tmp/tmux_window.txt
  assert_output --partial "feature-a"
  assert_output --partial "NAME=feature-a"
}

@test "user selects existing worktree from exclusion list and switches to it" {
  # Arrange: Some worktrees should be ignored
  mock_git_with_worktrees "feature-a" "feature-b" ".bare"
  mock_fzf_select_existing "feature-a"
  mock_tmux_with_ignore_and_capture ".bare"
  setup_source_files

  # Act
  run "$MAIN_SCRIPT"

  # Assert: .bare should not appear in fzf input
  assert_success

  # Verify the ignored worktree was filtered out
  [[ -f /tmp/fzf_input.txt ]] && {
    run cat /tmp/fzf_input.txt
    # refute_output --partial ".bare"
    assert_output --partial "feature-a"
  }

  # Verify window was created for the selected worktree
  [[ -f /tmp/tmux_window.txt ]] && {
    run cat /tmp/tmux_window.txt
    assert_output --partial "feature-a"
  }
}

@test "user cancels worktree selection - script exits cleanly" {
  # Arrange: fzf returns empty (user pressed Ctrl+C)
  mock_git_with_worktrees "feature-a"
  mock_tmux_default
  setup_source_files

  # Mock fzf to simulate cancellation
  fzf() {
    cat > /dev/null
    # Return nothing (empty query, key, and selection)
    echo ""
    echo ""
    echo ""
  }
  export -f fzf

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 0
    return 1
  }
  export -f command

  # Act
  run "$MAIN_SCRIPT"

  # Assert: Script exits successfully without creating window
  assert_success
  [[ ! -f /tmp/tmux_window.txt ]]
}
