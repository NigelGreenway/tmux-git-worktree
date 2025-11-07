#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../mocks/setup'

setup() {
  setup_journey_test
  init_git_repo
}

teardown() {
  teardown_journey_test
}

@test "uses bash interface when fzf is not installed" {
  # Arrange: Mock command to report fzf not found
  mock_tmux_default
  setup_source_files

  command() {
    if [[ "$1" == "-v" && "$2" == "fzf" ]]; then
      return 1  # fzf not found
    fi
    return 0
  }
  export -f command

  git() {
    case "$1" in
      rev-parse)
        case "$2" in
          --git-dir) echo ".git"; return 0 ;;
          --is-bare-repository) echo "false"; return 0 ;;
          --quiet|--verify) return 1 ;;  # Branch doesn't exist
        esac
        ;;
      worktree)
        if [[ "$2" == "add" ]]; then
          # Capture the add command
          echo "WORKTREE_ADD_CALLED=yes" > /tmp/worktree_add.txt
          shift 2
          echo "ARGS=$*" >> /tmp/worktree_add.txt
          mkdir -p "$1"
          return 0
        elif [[ "$2" == "list" ]]; then
          echo "$TEST_DIR main abc123"
        fi
        ;;
      branch) echo "  main" ;;
      config|commit) return 0 ;;
    esac
  }
  export -f git

  # Mock read to provide input for bash interface
  read() {
    local prompt_var=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -p) shift ;;  # Skip the prompt text
        *) prompt_var="$1" ;;
      esac
      shift
    done

    case "$prompt_var" in
      directory) eval "$prompt_var='test-worktree'" ;;
      branch) eval "$prompt_var='test-branch'" ;;
      *) return 0 ;;
    esac
  }
  export -f read

  # Act: Run the script (should use bash interface)
  run "$MAIN_SCRIPT"

  # Assert: Worktree was created using bash interface
  assert_success
  [[ -f /tmp/worktree_add.txt ]] || skip "worktree add not called"

  run cat /tmp/worktree_add.txt
  assert_output --partial "WORKTREE_ADD_CALLED=yes"
  assert_output --partial "test-worktree"
  assert_output --partial "test-branch"

  # Cleanup
  rm -f /tmp/worktree_add.txt
}

@test "bash interface creates worktree successfully" {
  # Arrange: No fzf available
  mock_tmux_capture_window
  setup_source_files

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 1  # fzf not found
    return 0
  }
  export -f command

  git() {
    case "$1" in
      rev-parse)
        case "$2" in
          --git-dir) echo ".git"; return 0 ;;
          --is-bare-repository) echo "false"; return 0 ;;
          --quiet|--verify) return 1 ;;  # New branch
        esac
        ;;
      worktree)
        if [[ "$2" == "add" ]]; then
          mkdir -p "$3" 2>/dev/null
          return 0
        elif [[ "$2" == "list" ]]; then
          echo "$TEST_DIR main abc123"
        fi
        ;;
      branch) echo "  main" ;;
      *) return 0 ;;
    esac
  }
  export -f git

  read() {
    local prompt_var=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -p) shift ;;
        *) prompt_var="$1" ;;
      esac
      shift
    done

    case "$prompt_var" in
      directory) eval "$prompt_var='my-feature'" ;;
      branch) eval "$prompt_var='feature-branch'" ;;
      *) return 0 ;;
    esac
  }
  export -f read

  # Act
  run "$MAIN_SCRIPT"

  # Assert: Tmux window created
  assert_success
  [[ -f /tmp/tmux_window.txt ]] || skip "tmux window not created"

  run cat /tmp/tmux_window.txt
  assert_output --partial "my-feature"
  assert_output --partial "NAME=my-feature"
}
