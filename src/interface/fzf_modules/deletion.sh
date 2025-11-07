#!/usr/bin/env bash

confirm_worktree_deletion() {
  local wt_selection="$1"

  read -p "Delete worktree $wt_selection? [Y/n] " confirmation

  if [[ "$confirmation" == "n" || "$confirmation" == "N" ]]; then
    return 1
  fi

  return 0
}

delete_worktree() {
  local wt_selection="$1"
  local ttl="${2:-2}"

  debug "removing worktree: $wt_selection"

  if git worktree remove "$wt_selection"; then
    debug "removed worktree: $wt_selection"
    echo "Removed worktree: $wt_selection"
    sleep "$ttl"
    return 0
  fi

  return 1
}

handle_worktree_deletion() {
  local wt_selection="$1"
  local ttl="$2"

  debug "Deleting the worktree: $wt_selection"

  if confirm_worktree_deletion "$wt_selection"; then
    delete_worktree "$wt_selection" "$ttl"
  else
    debug "skipped deletion"
  fi
}
