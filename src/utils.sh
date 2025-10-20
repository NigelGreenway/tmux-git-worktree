#!/usr/bin/env bash

get_option_value() {
  local option="$1"
  local fallback="$2"
  local option_value

  option_value=$(tmux show -gqv "$option")

  if [[ -z "$option_value" ]]; then
    echo "$fallback"
  else
    echo "$option_value"
  fi
}

debug() {
  # This becomes a circular dependency between `debug` and `get_option_value`. So, we need
  # to call this and not set any debug statements in the `get_option_value` function
  verbose=$(get_option_value "@git-worktree-verbose" "0")
  if [[ "$verbose" -eq 1 ]]; then
    echo "[debug | Line ${BASH_LINENO[0]}]: $*" >&2
  fi
}

check_condition_and_error_on_fail() {
  local condition="$1"
  local message="$2"

  debug "check_condition_and_error_on_fail; condition: $condition, message: $message"

  if eval "$condition"; then
    echo "Error: $message"
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
  fi
}
