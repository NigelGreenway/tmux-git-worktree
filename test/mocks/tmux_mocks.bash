#!/usr/bin/env bash

# Basic tmux mock with no custom options
mock_tmux_default() {
  tmux() {
    case "$1" in
      show) echo "" ;;
      new-window) return 0 ;;
    esac
  }
  export -f tmux
}

# Mock tmux and capture new-window calls
mock_tmux_capture_window() {
  tmux() {
    case "$1" in
      show) echo "" ;;
      new-window)
        local path="" name=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -c) shift; path="$1" ;;
            -n) shift; name="$1" ;;
          esac
          shift
        done
        cat > /tmp/tmux_window.txt <<EOF
PATH=$path
NAME=$name
EOF
        return 0
        ;;
    esac
  }
  export -f tmux
}

# Mock tmux with custom ignore list
mock_tmux_with_ignore_list() {
  # Store ignore pattern in a global variable so the tmux function can access it
  MOCK_TMUX_IGNORE_PATTERN="$1"

  tmux() {
    case "$1" in
      show)
        if [[ "$3" == "@git-worktree-ignore-worktrees" ]]; then
          echo "$MOCK_TMUX_IGNORE_PATTERN"
        else
          echo ""
        fi
        ;;
      new-window) return 0 ;;
    esac
  }
  export -f tmux
}

# Mock tmux with custom ignore list AND capture window
mock_tmux_with_ignore_and_capture() {
  # Store ignore pattern in a global variable so the tmux function can access it
  MOCK_TMUX_IGNORE_PATTERN="$1"
  export MOCK_TMUX_IGNORE_PATTERN

  tmux() {
    case "$1" in
      show)
        if [[ "$3" == "@git-worktree-ignore-worktrees" ]]; then
          echo "$MOCK_TMUX_IGNORE_PATTERN"
        else
          echo ""
        fi
        ;;
      new-window)
        local path="" name=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -c) shift; path="$1" ;;
            -n) shift; name="$1" ;;
          esac
          shift
        done
        cat > /tmp/tmux_window.txt <<EOF
PATH=$path
NAME=$name
EOF
        return 0
        ;;
    esac
  }
  export -f tmux
}
