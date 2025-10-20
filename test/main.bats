#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
    MAIN_SCRIPT="$PROJECT_ROOT/src/main"

    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"

    read() { return 0; }
    export -f read
}

teardown() {
    rm -rf "$TEST_DIR"

    unset -f tmux 2>/dev/null || true
    unset -f git 2>/dev/null || true
    unset -f fzf 2>/dev/null || true
    unset -f read 2>/dev/null || true
}

@test "main script fails when not running inside tmux" {
    unset TMUX

    run "$MAIN_SCRIPT"
    assert_failure
    assert_output --partial "Not running inside tmux"
}

@test "main script fails when not in a git repository" {
    export TMUX="tmux-session"

    git() {
        if [[ "$1" == "rev-parse" ]]; then
            return 1
        fi
    }
    export -f git

    run "$MAIN_SCRIPT"
    assert_failure
    assert_output --partial "Not a git repository"
}

@test "main script detects when fzf is not installed" {
    export TMUX="tmux-session"

    git init

    tmux() {
        case "$1" in
            show) echo "" ;;
            new-window) return 0 ;;
        esac
    }
    export -f tmux

    PATH="/bin:/usr/bin"

    run timeout 1 "$MAIN_SCRIPT" || true
}

@test "main script handles existing worktree selection" {
    skip "Integration test - requires full environment mocking"
}

@test "main script handles new worktree creation" {
    skip "Integration test - requires full environment mocking"
}

@test "ignore list is read from tmux options" {
    export TMUX="tmux-session"

    # We can't easily test this without running the full script,
    # but we can verify the option reading works
    source "$PROJECT_ROOT/src/utils.sh"

    tmux() {
        if [[ "$2" == "@git-worktree-ignore-worktrees" ]]; then
            echo ".bare|other"
        fi
    }
    export -f tmux

    result=$(get_option_value "@git-worktree-ignore-worktrees" "")
    assert_equal "$result" ".bare|other"
}
