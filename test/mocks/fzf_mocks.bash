#!/usr/bin/env bash

# Mock fzf to select an existing worktree
mock_fzf_select_existing() {
  local selection="$1"

  fzf() {
    # Consume and save input for debugging
    cat > /tmp/fzf_input.txt

    # Simulate user selecting an existing worktree
    echo ""           # query (empty - user didn't type)
    echo ""           # key (no special key pressed)
    echo "$selection" # selection
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
  local wt_name="$1"
  local branch_name="$2"
  local commit_ref="${3:-}"

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
        echo "$wt_name"  # query
        echo ""          # key
        echo ""          # selection (empty - doesn't exist)
        ;;
      2)
        # Second call: Branch selection - user types new branch
        echo "$branch_name"  # query
        echo ""              # selection (empty - user typed)
        ;;
      3)
        # Third call: Commit selection (if branch is new)
        echo "$commit_ref"
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
  local wt_to_delete="$1"
  local delete_key="$2"

  fzf() {
    cat > /dev/null  # Consume input

    echo ""                  # query (empty)
    echo "$delete_key"       # key pressed
    echo "$wt_to_delete"     # selection
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
  local wt_name="$1"
  local branch_name="$2"

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
        echo "$wt_name"  # query
        echo ""          # key
        echo ""          # selection
        ;;
      2)
        # Second call: Branch selection - user selects existing
        echo ""              # query (empty - user selected)
        echo "$branch_name"  # selection
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
