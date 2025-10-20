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

Add the following with your own keybinding to trigger the script in a popup:

```tmux
bind-key C-g display-popup -E -w 80% -h 60% -d "#{pane_current_path}" "<YOUR_PATH_TO_YOUR_TMUX_CONFIG>/plugins/tmux-git-worktree/src/main"
```

## Configuration options

### Enable verbose

When developing or debugging against this plugin, you can set the verbose flag in your config, reload and see any debug statements to help squash a bug or add a new feature.

When not set, it default's to `0` which is off. To enable, set it to `1`.

```tmux
set -g @git-worktree-verbose 1
```

### Ignoring worktrees

You can ignore multiple worktrees with the separator `|`.

```tmux
set -g @git-worktree-ignore-worktrees ".bare|other-worktree"
```
