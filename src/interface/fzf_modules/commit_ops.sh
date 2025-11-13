#!/usr/bin/env bash

select_commit_with_fzf() {
  local show_commit_ref_binding="$1"

  git branch -a |\
    sed 's/^[* ] //' |\
    sed 's/remotes\///' |\
    fzf \
      --print-query \
      --header="Enter: Select branch | $show_commit_ref_binding: switch to commit refs" \
      --bind="$show_commit_ref_binding:become(git --no-pager log --no-color --oneline --no-merges --decorate | fzf --print-query  --prompt='Select commit ref: ' | tail -1 | awk '{print \$1}')" |\
    awk '{if (NF > 1) print $2; else print $1}' |\
    tail -1
}
