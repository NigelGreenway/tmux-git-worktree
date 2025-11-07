#!/usr/bin/env bash

get_worktree_list() {
  local ignore_pattern="${1:-}"

  git worktree list | \
    grep -v -E "($ignore_pattern)" | \
    awk '{print $1}' | \
    xargs -n1 basename
}

select_worktree_with_fzf() {
  local header="$1"
  local delete_binding="$2"

  fzf \
    --print-query \
    --expect="$delete_binding" \
    --prompt="Select or create worktree: " \
    --header="$header"
}

parse_worktree_selection() {
  # Parse fzf output from response array into variables
  # Expects: response array already populated via readarray
  # Sets: wt_query, wt_key, wt_selection
  wt_query="${response[0]}"
  wt_key="${response[1]}"
  wt_selection="${response[2]}"
}

check_worktree_exists() {
  local wt_name="$1"
  git worktree list | awk -v dir="$wt_name" '$1 ~ "/"dir"$" {print; exit}'
}
