#!/usr/bin/env bash

# Mock fzf to select an existing worktree
mock_fzf_select_existing() {
  # Store selection in a global variable so the fzf function can access it
  MOCK_FZF_SELECTION="$1"
  export MOCK_FZF_SELECTION

  fzf() {
    # Consume and save input for debugging
    cat > /tmp/fzf_input.txt

    # Simulate user selecting an existing worktree
    echo ""                      # query (empty - user didn't type)
    echo ""                      # key (no special key pressed)
    echo "$MOCK_FZF_SELECTION"   # selection
  }
  export -f fzf

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 0
    return 1
  }
  export -f command
}

# Mock fzf for new worktree creation journey
mock_fzf_create_worktree() {
  # Store parameters in global variables so the fzf function can access them
  MOCK_FZF_WT_NAME="$1"
  MOCK_FZF_BRANCH_NAME="$2"
  MOCK_FZF_COMMIT_REF="${3:-}"
  export MOCK_FZF_WT_NAME MOCK_FZF_BRANCH_NAME MOCK_FZF_COMMIT_REF

  fzf() {
    local count_file="/tmp/fzf_call_count"
    [[ ! -f "$count_file" ]] && echo "0" > "$count_file"

    local call_count=$(cat "$count_file")
    call_count=$((call_count + 1))
    echo "$call_count" > "$count_file"

    # Consume input
    cat > /dev/null

    case $call_count in
      1)
        # First call: Worktree selection - user types new name
        echo "$MOCK_FZF_WT_NAME"  # query
        echo ""                   # key
        echo ""                   # selection (empty - doesn't exist)
        ;;
      2)
        # Second call: Branch selection - user types new branch
        echo "$MOCK_FZF_BRANCH_NAME"  # query
        echo ""                       # selection (empty - user typed)
        ;;
      3)
        # Third call: Commit selection (if branch is new)
        echo "$MOCK_FZF_COMMIT_REF"
        ;;
    esac
  }
  export -f fzf

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 0
    return 1
  }
  export -f command
}

# Mock fzf for deletion flow
mock_fzf_delete_worktree() {
  # Store parameters in global variables so the fzf function can access them
  MOCK_FZF_WT_TO_DELETE="$1"
  MOCK_FZF_DELETE_KEY="$2"
  export MOCK_FZF_WT_TO_DELETE MOCK_FZF_DELETE_KEY

  fzf() {
    cat > /dev/null  # Consume input

    echo ""                        # query (empty)
    echo "$MOCK_FZF_DELETE_KEY"    # key pressed
    echo "$MOCK_FZF_WT_TO_DELETE"  # selection
  }
  export -f fzf

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 0
    return 1
  }
  export -f command
}

# Mock fzf for user selecting existing branch
mock_fzf_select_existing_branch() {
  # Store parameters in global variables so the fzf function can access them
  MOCK_FZF_WT_NAME="$1"
  MOCK_FZF_BRANCH_NAME="$2"
  export MOCK_FZF_WT_NAME MOCK_FZF_BRANCH_NAME

  fzf() {
    local count_file="/tmp/fzf_call_count"
    [[ ! -f "$count_file" ]] && echo "0" > "$count_file"

    local call_count=$(cat "$count_file")
    call_count=$((call_count + 1))
    echo "$call_count" > "$count_file"

    cat > /dev/null  # Consume input

    case $call_count in
      1)
        # First call: Worktree selection - user types new name
        echo "$MOCK_FZF_WT_NAME"  # query
        echo ""                   # key
        echo ""                   # selection
        ;;
      2)
        # Second call: Branch selection - user selects existing
        echo ""                       # query (empty - user selected)
        echo "$MOCK_FZF_BRANCH_NAME"  # selection
        ;;
    esac
  }
  export -f fzf

  command() {
    [[ "$1 $2" == "-v fzf" ]] && return 0
    return 1
  }
  export -f command
}
