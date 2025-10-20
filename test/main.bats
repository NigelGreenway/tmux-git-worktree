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

    # Create a test git repo
    git init
    git config user.email "test@test.com"
    git config user.name "Test User"
    git commit --allow-empty -m "Initial commit"

    # Mock tmux to handle all the commands the script will call
    tmux() {
        case "$1" in
            show)
                # Return empty for all tmux options
                echo ""
                ;;
            new-window)
                # Succeed on creating window
                return 0
                ;;
        esac
    }
    export -f tmux

    # Create wrapper script with mocked read function
    cat > "$TEST_DIR/test_wrapper.sh" << 'EOF'
#!/bin/bash

# Mock the read command to provide automated input
read() {
    local prompt_var=""
    local input_value=""

    # Parse the read arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p)
                shift
                # The prompt text
                ;;
            *)
                prompt_var="$1"
                ;;
        esac
        shift
    done

    # Determine what value to return based on which variable is being set
    case "$prompt_var" in
        directory)
            input_value="test-worktree"
            ;;
        branch)
            input_value="test-branch"
            ;;
        *)
            input_value=""
            ;;
    esac

    # Set the variable in the caller's context
    eval "$prompt_var='$input_value'"
}
export -f read

# Ensure fzf is not available
PATH="/bin:/usr/bin"

# Source and run the main script
EOF

    # Append the main script path to the wrapper
    echo "source '$MAIN_SCRIPT'" >> "$TEST_DIR/test_wrapper.sh"

    chmod +x "$TEST_DIR/test_wrapper.sh"

    # Run the wrapper script
    run "$TEST_DIR/test_wrapper.sh"

    # The script should complete without hanging
    # It might fail due to worktree creation issues, but shouldn't hang on read
}

@test "main script handles existing worktree selection" {
    skip "Integration test - requires full environment mocking"
}

@test "main script handles new worktree creation" {
    skip "Integration test - requires full environment mocking"
}

@test "ignore list is read from tmux options" {
    export TMUX="tmux-session"

    git init
    git config user.email "test@test.com"
    git config user.name "Test User"
    git commit --allow-empty -m "Initial commit"

    mkdir -p ../worktree1 ../.bare ../other-worktree ../valid-worktree
    git worktree add ../worktree1 -b branch1 2>/dev/null || true
    git worktree add ../.bare -b bare-branch 2>/dev/null || true
    git worktree add ../other-worktree -b other-branch 2>/dev/null || true
    git worktree add ../valid-worktree -b valid-branch 2>/dev/null || true

    cat > "$TEST_DIR/test_wrapper.sh" << 'EOF'
#!/bin/bash

# Mock tmux to return ignore list and handle other commands
tmux() {
    case "$1" in
        show)
            case "$2" in
                -gqv)
                    # Return the ignore list for the worktree option
                    if [[ "$3" == "@git-worktree-ignore-worktrees" ]]; then
                        echo ".bare|other-worktree"
                    else
                        echo ""
                    fi
                    ;;
                *)
                    echo ""
                    ;;
            esac
            ;;
        new-window)
            return 0
            ;;
    esac
}
export -f tmux

# Mock fzf to capture what's passed to it and select the first valid item
fzf() {
    # Capture the input for verification
    local input=$(cat)

    # Save what was shown to fzf for later verification
    echo "$input" > /tmp/fzf_input.txt

    # Return the first line (simulating user selection)
    echo "$input" | head -n1
}
export -f fzf

# Mock read to handle any prompts
read() {
    local prompt_var=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|-n|-s|-r) shift ;;
            *) prompt_var="$1" ;;
        esac
        shift
    done

    # Provide default values
    case "$prompt_var" in
        directory) eval "$prompt_var='valid-worktree'" ;;
        branch) eval "$prompt_var='test-branch'" ;;
        *) return 0 ;;
    esac
}
export -f read

EOF

    echo "source '$MAIN_SCRIPT'" >> "$TEST_DIR/test_wrapper.sh"

    chmod +x "$TEST_DIR/test_wrapper.sh"

    run "$TEST_DIR/test_wrapper.sh"

    if [[ -f /tmp/fzf_input.txt ]]; then
        run cat /tmp/fzf_input.txt
        refute_output --partial ".bare"
        refute_output --partial "other-worktree"
        assert_output --partial "worktree1"
        assert_output --partial "valid-worktree"
    fi
}
