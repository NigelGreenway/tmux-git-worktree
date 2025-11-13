#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
    source "$PROJECT_ROOT/src/interface/fzf_modules/worktree_ops.sh"
}

teardown() {
    unset -f git 2>/dev/null || true
}

@test "get_worktree_list returns all worktrees when no ignore pattern" {
    # Mock git worktree list
    git() {
        if [[ "$1 $2" == "worktree list" ]]; then
            echo "/path/to/repo main abc123"
            echo "/path/to/repo/../feature-a branch-a def456"
            echo "/path/to/repo/../feature-b branch-b ghi789"
        fi
    }
    export -f git

    run get_worktree_list ""

    assert_success
    assert_line --index 0 "repo"
    assert_line --index 1 "feature-a"
    assert_line --index 2 "feature-b"
}

@test "get_worktree_list filters worktrees with ignore pattern" {
    # Mock git worktree list
    git() {
        if [[ "$1 $2" == "worktree list" ]]; then
            echo "/path/to/repo main abc123"
            echo "/path/to/repo/../feature-a branch-a def456"
            echo "/path/to/repo/../feature-b branch-b ghi789"
            echo "/path/to/repo/../.bare bare-branch jkl012"
        fi
    }
    export -f git

    run get_worktree_list ".bare"

    assert_success
    assert_line --index 0 "repo"
    assert_line --index 1 "feature-a"
    assert_line --index 2 "feature-b"
    refute_output --partial ".bare"
}

@test "get_worktree_list handles empty worktree list" {
    # Mock git worktree list with no results
    git() {
        if [[ "$1 $2" == "worktree list" ]]; then
            echo "/path/to/repo main abc123"
        fi
    }
    export -f git

    run get_worktree_list ""

    assert_success
    assert_line --index 0 "repo"
}

@test "get_worktree_list with pattern that matches nothing" {
    # Mock git worktree list
    git() {
        if [[ "$1 $2" == "worktree list" ]]; then
            echo "/path/to/repo main abc123"
            echo "/path/to/repo/../feature-a branch-a def456"
        fi
    }
    export -f git

    run get_worktree_list "nonexistent"

    assert_success
    assert_line --index 0 "repo"
    assert_line --index 1 "feature-a"
}

@test "parse_worktree_selection sets variables correctly" {
    source "$PROJECT_ROOT/src/interface/fzf_modules/worktree_ops.sh"

    # Simulate readarray output
    response=("my-query" "ctrl-d" "selected-item")

    parse_worktree_selection

    [[ "$wt_query" == "my-query" ]]
    [[ "$wt_key" == "ctrl-d" ]]
    [[ "$wt_selection" == "selected-item" ]]
}

@test "check_worktree_exists returns worktree when it exists" {
    git() {
        if [[ "$1 $2" == "worktree list" ]]; then
            echo "/path/to/repo main abc123"
            echo "/path/to/repo/feature-a branch-a def456"
        fi
    }
    export -f git

    run check_worktree_exists "feature-a"

    assert_success
    assert_output --partial "/path/to/repo/feature-a"
}

@test "check_worktree_exists returns nothing when worktree doesn't exist" {
    git() {
        if [[ "$1 $2" == "worktree list" ]]; then
            echo "/path/to/repo main abc123"
        fi
    }
    export -f git

    run check_worktree_exists "nonexistent"

    assert_success
    refute_output --partial "nonexistent"
}
