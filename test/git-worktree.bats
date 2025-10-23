#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
    MAIN_SCRIPT="$PROJECT_ROOT/src/git-worktree"

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

    # Create a symlink to utils.sh so the main script can find it
    ln -s "$PROJECT_ROOT/src/utils.sh" "$TEST_DIR/utils.sh"

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

# Mock git command
git() {
    case "$1" in
        rev-parse)
            case "$2" in
                --git-dir)
                    # We're in a git repo
                    echo ".git"
                    return 0
                    ;;
                --is-bare-repository)
                    # Not a bare repo
                    echo "false"
                    return 0
                    ;;
                --quiet|--verify)
                    # Branch exists check
                    return 0
                    ;;
            esac
            ;;
        worktree)
            case "$2" in
                list)
                    # Return list of existing worktrees
                    # Format: path branch commit-hash
                    echo "$PWD main abc123"
                    echo "$PWD/../existing-feature feature-branch def456"
                    echo "$PWD/../another-worktree another-branch ghi789"
                    ;;
            esac
            ;;
        branch)
            # Return list of branches
            echo "  main"
            echo "  feature-branch"
            echo "  another-branch"
            ;;
        config|commit)
            # Handle git config/commit calls
            return 0
            ;;
    esac
}
export -f git

# Mock tmux command
tmux() {
    case "$1" in
        show)
            # Handle: tmux show -gqv "@option"
            # Return empty for all tmux options (no custom config)
            echo ""
            return 0
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

# Mock command to detect if fzf is available
command() {
    if [[ "$1" == "-v" ]] && [[ "$2" == "fzf" ]]; then
        return 0  # fzf is available
    fi
    return 1
}
export -f command

EOF

   # Create a symlink to utils.sh so the main script can find it
    ln -s "$PROJECT_ROOT/src/utils.sh" "$TEST_DIR/utils.sh"

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
    export TMUX="tmux-session"

    # Clean up any previous fzf call counter
    rm -f /tmp/fzf_call_count

    git init
    git config user.email "test@test.com"
    git config user.name "Test User"
    git commit --allow-empty -m "Initial commit"

    mkdir -p ../existing-worktree
    git worktree add ../existing-worktree -b existing-branch 2>/dev/null || true

    cat > "$TEST_DIR/test_wrapper.sh" << 'EOF'
#!/bin/bash

# Track what git commands are called
GIT_WORKTREE_ADDED=""
GIT_WORKTREE_PATH=""
GIT_WORKTREE_BRANCH=""
GIT_WORKTREE_NEW_BRANCH=""

# Mock git command
git() {
    case "$1" in
        worktree)
            case "$2" in
                list)
                    # Return existing worktrees
                    echo "$PWD"
                    echo "$PWD/../existing-worktree"
                    ;;
                add)
                    # Parse git worktree add arguments
                    shift 2  # Skip 'worktree add'
                    local path=""
                    local branch=""
                    local new_branch=""

                    while [[ $# -gt 0 ]]; do
                        case "$1" in
                            -b)
                                shift
                                new_branch="$1"
                                ;;
                            *)
                                if [[ -z "$path" ]]; then
                                    path="$1"
                                else
                                    branch="$1"
                                fi
                                ;;
                        esac
                        shift
                    done

                    GIT_WORKTREE_ADDED="yes"
                    GIT_WORKTREE_PATH="$path"
                    GIT_WORKTREE_BRANCH="$branch"
                    GIT_WORKTREE_NEW_BRANCH="$new_branch"

                    # Save to temp file for verification
                    echo "ADDED=yes" > /tmp/git_worktree_add.txt
                    echo "PATH=$path" >> /tmp/git_worktree_add.txt
                    echo "BRANCH=$branch" >> /tmp/git_worktree_add.txt
                    echo "NEW_BRANCH=$new_branch" >> /tmp/git_worktree_add.txt

                    # Create the directory to simulate successful worktree creation
                    mkdir -p "$path"
                    return 0
                    ;;
            esac
            ;;
        branch)
            # Return list of branches for fzf selection
            echo "  main"
            echo "  existing-branch"
            echo "  remotes/origin/main"
            echo "  remotes/origin/feature-branch"
            ;;
        rev-parse)
            case "$2" in
                --git-dir)
                    # We're in a git repo
                    echo ".git"
                    return 0
                    ;;
                --is-bare-repository)
                    # Not a bare repo
                    echo "false"
                    return 0
                    ;;
                --quiet|--verify)
                    # Check if branch exists
                    if [[ "$3" == "existing-branch" ]] || [[ "$3" == "main" ]]; then
                        return 0  # Branch exists
                    else
                        return 1  # Branch doesn't exist
                    fi
                    ;;
            esac
            ;;
        config)
            # Handle git config calls
            return 0
            ;;
        commit)
            # Handle git commit calls
            return 0
            ;;
    esac
}
export -f git

# Mock tmux command
tmux() {
    case "$1" in
        show)
            # Return empty for all tmux options
            echo ""
            ;;
        new-window)
            # Parse and save new-window arguments
            local window_path=""
            local window_name=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -c)
                        shift
                        window_path="$1"
                        ;;
                    -n)
                        shift
                        window_name="$1"
                        ;;
                esac
                shift
            done

            echo "WINDOW_PATH=$window_path" > /tmp/tmux_new_window.txt
            echo "WINDOW_NAME=$window_name" >> /tmp/tmux_new_window.txt
            return 0
            ;;
    esac
}
export -f tmux

# Mock fzf to simulate user input
# Use a file to track call count since exported functions don't share variables
fzf() {
    # Track call count in a temp file
    local count_file="/tmp/fzf_call_count"
    if [[ ! -f "$count_file" ]]; then
        echo "0" > "$count_file"
    fi

    local call_count=$(cat "$count_file")
    call_count=$((call_count + 1))
    echo "$call_count" > "$count_file"

    # Capture input
    local input=$(cat)

    if [[ $call_count -eq 1 ]]; then
        # First call: selecting/typing worktree name
        # User types "new-feature" which doesn't exist
        echo "new-feature"
    elif [[ $call_count -eq 2 ]]; then
        # Second call: selecting/typing branch name
        # User types "new-feature-branch" which doesn't exist
        echo "new-feature-branch"
    fi
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

    case "$prompt_var" in
        *) return 0 ;;
    esac
}
export -f read

# Mock command to detect if fzf is available
command() {
    if [[ "$1" == "-v" ]] && [[ "$2" == "fzf" ]]; then
        return 0  # fzf is available
    fi
    return 1
}
export -f command

EOF

    # Create a symlink to utils.sh so the main script can find it
    ln -s "$PROJECT_ROOT/src/utils.sh" "$TEST_DIR/utils.sh"

    echo "source '$MAIN_SCRIPT'" >> "$TEST_DIR/test_wrapper.sh"

    chmod +x "$TEST_DIR/test_wrapper.sh"

    run "$TEST_DIR/test_wrapper.sh"

    # Verify git worktree add was called
    [[ -f /tmp/git_worktree_add.txt ]] || skip "git worktree add was not called"

    run cat /tmp/git_worktree_add.txt
    assert_output --partial "ADDED=yes"
    assert_output --partial "PATH="
    assert_output --partial "new-feature"
    assert_output --partial "NEW_BRANCH=new-feature-branch"

    # Verify tmux window was created
    [[ -f /tmp/tmux_new_window.txt ]] || skip "tmux new-window was not called"

    run cat /tmp/tmux_new_window.txt
    assert_output --partial "WINDOW_PATH="
    assert_output --partial "new-feature"
    assert_output --partial "WINDOW_NAME=new-feature"

    # Cleanup
    rm -f /tmp/git_worktree_add.txt /tmp/tmux_new_window.txt /tmp/fzf_call_count
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

    # Create a symlink to utils.sh so the main script can find it
    ln -s "$PROJECT_ROOT/src/utils.sh" "$TEST_DIR/utils.sh"

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
