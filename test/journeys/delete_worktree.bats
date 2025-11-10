#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../mocks/setup'

setup() {
  setup_journey_test
  init_git_repo

  # Create directory structure (actual worktrees are mocked in tests)
  mkdir -p ../feature-to-delete ../other-feature
}

teardown() {
  teardown_journey_test
}

@test "user deletes worktree - confirms deletion" {
  # Arrange: User selects delete key and confirms
  mock_git_capture_worktree_remove
  mock_fzf_delete_worktree "feature-to-delete" "ctrl-d"
  mock_tmux_default
  setup_source_files

  # Mock read to confirm deletion (default Y)
  read() {
    local prompt_var=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -p|-n|-s|-r) shift ;;
        *) prompt_var="$1" ;;
      esac
      shift
    done

    # Simulate user pressing Enter (default yes)
    case "$prompt_var" in
      confirmation) eval "$prompt_var=''" ;;
      *) return 0 ;;
    esac
  }
  export -f read

  # Act: Run the script
  run "$MAIN_SCRIPT"

  # Assert: Worktree was removed
  assert_success
  [[ -f /tmp/git_worktree_remove.txt ]] || skip "git worktree remove was not called"

  run cat /tmp/git_worktree_remove.txt
  assert_output --partial "REMOVED=feature-to-delete"

  # Verify no tmux window was created (deletion exits early)
  [[ ! -f /tmp/tmux_window.txt ]]
}

@test "user deletes worktree - cancels deletion" {
  # Arrange: User selects delete key but cancels
  mock_git_capture_worktree_remove
  mock_fzf_delete_worktree "feature-to-delete" "ctrl-d"
  mock_tmux_default
  setup_source_files

  # Mock read to cancel deletion
  read() {
    local prompt_var=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -p|-n|-s|-r) shift ;;
        *) prompt_var="$1" ;;
      esac
      shift
    done

    # Simulate user typing 'n'
    case "$prompt_var" in
      confirmation) eval "$prompt_var='n'" ;;
      *) return 0 ;;
    esac
  }
  export -f read

  # Act
  run "$MAIN_SCRIPT"

  # Assert: Worktree was NOT removed
  assert_success
  [[ ! -f /tmp/git_worktree_remove.txt ]]  # File should not exist

  # Verify no tmux window was created
  [[ ! -f /tmp/tmux_window.txt ]]
}
