#!/usr/bin/env bash

get_worktree_list() {
  local ignore_pattern="${1:-}"

  if [[ -z "$ignore_pattern" ]]; then
    git worktree list | awk '{print $1}' | xargs -n1 basename
  else
    git worktree list | awk '{print $1}' | grep -v -F "$ignore_pattern" | xargs -n1 basename
  fi
}

select_worktree_with_fzf() {
  local header="$1"
  local delete_binding="$2"
  local switch_pane_binding="$3"
  local new_window_binding="$4"
  local split_pane_binding="$5"

  fzf \
    --print-query \
    --expect="$delete_binding,$switch_pane_binding,$new_window_binding,$split_pane_binding" \
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
