# tmux-git-worktree

An opinionated plugin to select or create git worktree's and branches, and then open in a new window within the current tmux session.

## Dependencies

 - [fzf](https://github.com/junegunn/fzf)

## Installation with Tmux Plugin Manager (recommended)

Add plugin to the list of [TPM](https://github.com/tmux-plugins/tpm) plugins in your `.tmux.conf`:

```tmux
set -g @plugin 'NigelGreenway/tmux-git-workflow'
```

Hit <prefix> + I to fetch the plugin and source it.

## Usage

This is set to the key binding of `C-g` which will trigger a `display-popup` and ask for the worktree name and then the branch.
