#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../mocks/setup'

setup() {
  setup_journey_test
}

teardown() {
  teardown_journey_test
}

@test "script fails when not running inside tmux" {
  # Arrange: Unset TMUX environment variable
  unset TMUX

  # Act: Run the script
  run "$MAIN_SCRIPT"

  # Assert: Script exits with failure and shows error
  assert_failure
  assert_output --partial "Not running inside tmux"
}

@test "script fails when not in a git repository" {
  # Arrange: Mock git to return failure for rev-parse
  git() {
    if [[ "$1" == "rev-parse" ]]; then
      return 1
    fi
  }
  export -f git

  # Act: Run the script
  run "$MAIN_SCRIPT"

  # Assert: Script exits with failure and shows error
  assert_failure
  assert_output --partial "Not a git repository"
}

@test "script fails when branch name is empty during new worktree creation" {
  # Arrange: User types worktree name but provides empty branch
  init_git_repo
  mock_tmux_default
  setup_source_files

  # Mock fzf to return empty branch
  fzf() {
    local count_file="/tmp/fzf_call_count"
    [[ ! -f "$count_file" ]] && echo "0" > "$count_file"

    local call_count=$(cat "$count_file")
    call_count=$((call_count + 1))
    echo "$call_count" > "$count_file"

    cat > /dev/null  # Consume input

    case $call_count in
      1)
        # User types new worktree name
        echo "new-worktree"
        echo ""
        echo ""
        ;;
      2)
        # User doesn't type or select a branch (both empty)
        echo ""
        echo ""
        ;;
    esac
  }
  export -f fzf

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 0
    return 1
  }
  export -f command

  git() {
    case "$1" in
      rev-parse) echo ".git"; return 0 ;;
      worktree) echo "$TEST_DIR main abc123" ;;
      branch) echo "  main" ;;
      *) return 0 ;;
    esac
  }
  export -f git

  # Act
  run "$MAIN_SCRIPT"

  # Assert: Script fails with helpful error
  assert_failure
  assert_output --partial "Branch name cannot be empty"
}
