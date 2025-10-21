#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
    source "$PROJECT_ROOT/src/utils.sh"
}

teardown() {
    unset -f tmux 2>/dev/null || true
}

@test "get_option_value returns fallback when option is empty" {
    tmux() { echo ""; }
    export -f tmux

    result=$(get_option_value "@test-option" "fallback-value")
    assert_equal "$result" "fallback-value"
}

@test "get_option_value returns option value when set" {
    tmux() { echo "custom-value"; }
    export -f tmux

    result=$(get_option_value "@test-option" "fallback-value")
    assert_equal "$result" "custom-value"
}

@test "get_option_value handles empty fallback" {
    tmux() { echo ""; }
    export -f tmux

    result=$(get_option_value "@test-option" "")
    assert_equal "$result" ""
}

@test "debug outputs message when verbose is enabled" {
    tmux() { echo "1"; }
    export -f tmux

    run debug "test message"
    assert_output --partial "test message"
    assert_output --partial "[debug | Line"
}

@test "debug does not output when verbose is disabled" {
    tmux() { echo "0"; }
    export -f tmux

    run debug "test message"
    refute_output --partial "test message"
}

@test "debug does not output when verbose is not set" {
    tmux() { echo ""; }
    export -f tmux

    run debug "test message"
    refute_output --partial "test message"
}

@test "check_condition_and_error_on_fail exits when condition is true" {
    tmux() { echo "0"; }
    export -f tmux

    read() { return 0; }
    export -f read

    run check_condition_and_error_on_fail 'true' 'Test error message'
    assert_failure
    assert_output --partial "Error: Test error message"
}

@test "check_condition_and_error_on_fail succeeds when condition is false" {
    tmux() { echo "0"; }
    export -f tmux

    run check_condition_and_error_on_fail 'false' 'Test error message'
    assert_success
    refute_output --partial "Error: Test error message"
}

@test "check_condition_and_error_on_fail evaluates complex conditions" {
    tmux() { echo "0"; }
    export -f tmux

    read() { return 0; }
    export -f read

    run check_condition_and_error_on_fail '[[ "test" == "test" ]]' 'Should fail'
    assert_failure
    assert_output --partial "Error: Should fail"
}

@test "check_condition_and_error_on_fail handles empty string condition" {
    tmux() { echo "0"; }
    export -f tmux

    read() { return 0; }
    export -f read

    run check_condition_and_error_on_fail '[[ -z "" ]]' 'Should fail on empty'
    assert_failure
}

@test "directory names are sanitized correctly" {
    result=$(clean_directory "test directory")
    assert_equal "$result" "test-directory"
}

@test "branch names are sanitized correctly" {
    result=$(clean_branch_name "feature branch")
    assert_equal "$result" "feature-branch"
}

@test "branch names strip remote prefix correctly" {
    result=$(clean_branch_name "origin/main")
    assert_equal "$result" "main"

    result=$(clean_branch_name "upstream/develop")
    assert_equal "$result" "develop"
}

@test "window name removes ../ prefix correctly" {
    result=$(clean_window_name "../worktree-name")
    assert_equal "$result" "worktree-name"
}

@test "window name handles multiple ../ correctly" {
    result=$(clean_window_name "../../worktree-name")
    assert_equal "$result" "worktree-name"
}

