#!/usr/bin/env bash

get_branch_list() {
  git branch -a | \
    sed 's/^[* ] //' | \
    sed 's/remotes\///'
}

select_branch_with_fzf() {
  get_branch_list | \
    fzf --print-query --prompt="Select or type branch: "
}

parse_branch_selection() {
  # Parse fzf output from response array into variables
  # Expects: response array already populated via readarray
  # Sets: branch_query, branch_selection
  branch_query=$(echo "${response[0]}" | sed 's/\n//')
  branch_selection=$(echo "${response[1]}" | sed 's/\n//')
}
