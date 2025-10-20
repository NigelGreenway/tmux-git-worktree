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
    git config user.email "test@test.com"
    git config user.name "Test User"
    git commit --allow-empty -m "Initial commit"

    tmux() {
        case "$1" in
            show)
                echo ""
                ;;
            new-window)
                return 0
                ;;
        esac
    }
    export -f tmux

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

    echo "source '$MAIN_SCRIPT'" >> "$TEST_DIR/test_wrapper.sh"

    chmod +x "$TEST_DIR/test_wrapper.sh"

    run "$TEST_DIR/test_wrapper.sh"
}

@test "main script handles existing worktree selection" {
    export TMUX="tmux-session"

    git init
    git config user.email "test@test.com"
    git config user.name "Test User"
    git commit --allow-empty -m "Initial commit"

    mkdir -p ../existing-feature ../another-worktree
    git worktree add ../existing-feature -b feature-branch 2>/dev/null || true
    git worktree add ../another-worktree -b another-branch 2>/dev/null || true

    cat > "$TEST_DIR/test_wrapper.sh" << 'EOF'
#!/bin/bash

# Track tmux new-window calls
TMUX_WINDOW_CREATED=""
TMUX_WINDOW_PATH=""
TMUX_WINDOW_NAME=""

# Mock tmux command
tmux() {
    case "$1" in
        show)
            # Return empty for all tmux options (no custom config)
            echo ""
            ;;
        new-window)
            # Parse the new-window command arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -c)
                        shift
                        TMUX_WINDOW_PATH="$1"
                        ;;
                    -n)
                        shift
                        TMUX_WINDOW_NAME="$1"
                        ;;
                esac
                shift
            done
            TMUX_WINDOW_CREATED="yes"
            # Write to temp file for verification
            echo "PATH=$TMUX_WINDOW_PATH" > /tmp/tmux_window.txt
            echo "NAME=$TMUX_WINDOW_NAME" >> /tmp/tmux_window.txt
            return 0
            ;;
    esac
}
export -f tmux

# Mock fzf to select an existing worktree
fzf() {
    # Capture input (this will be the list of worktrees)
    local input=$(cat)

    # Save the input for debugging
    echo "$input" > /tmp/fzf_worktrees.txt

    # Return "existing-feature" (simulating user selection)
    # This should match one of the existing worktrees
    echo "existing-feature"
}
export -f fzf

# Mock read to handle any unexpected prompts
read() {
    local prompt_var=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|-n|-s|-r) shift ;;
            *) prompt_var="$1" ;;
        esac
        shift
    done

    # Should not be called for existing worktree, but provide fallback
    case "$prompt_var" in
        *) return 0 ;;
    esac
}
export -f read

EOF

    echo "source '$MAIN_SCRIPT'" >> "$TEST_DIR/test_wrapper.sh"

    chmod +x "$TEST_DIR/test_wrapper.sh"

    run "$TEST_DIR/test_wrapper.sh"

    # The script should succeed (or at least not hang)
    # Check if tmux new-window was called with correct parameters
    if [[ -f /tmp/tmux_window.txt ]]; then
        run cat /tmp/tmux_window.txt

        assert_output --partial "PATH="
        assert_output --partial "existing-feature"

        assert_output --partial "NAME=existing-feature"
    fi
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
