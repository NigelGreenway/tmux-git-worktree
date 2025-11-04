# tmux-git-worktree

An opinionated plugin to select or create git worktree's and branches, and then open in a new window within the current tmux session.

The problem was down to being lazy: I didn't want to have to create a new tmux window -> create a worktree -> select or create a branch -> select a commit reference to branch off (default is `HEAD` - current tip in that branch). I mean why when with one keybinding, two input prompts and it's done.

![Demo of tmux git worktree plugin](./assets/demo.webp "Demo of Git Worktree tmux plugin")

## Dependencies

 - [fzf](https://github.com/junegunn/fzf)

## Installation with Tmux Plugin Manager (recommended)

Add plugin to the list of [TPM](https://github.com/tmux-plugins/tpm) plugins in your `.tmux.conf`:

```tmux
set -g @plugin 'NigelGreenway/tmux-git-workflow'
```

Hit <prefix> + I to fetch the plugin and source it.

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

### Display popup configuration

It is possible to customise the display popup with the keybinding, width and the height.

```tmux
set -g @git-worktree-keybinding "M-g"   # Default is C-g
set -g @git-worktree-popup-width "90"   # Default is 80
set -g @@git-worktree-popup-height "20" # Default is 60
```

### Functionality configuration

```tmux
set -g @git-worktree-modifer "ctrl"     # Default is ctrl
set -g @git-worktree-delete-key "d"     # Default is d
set -g @git-worktree-ttl "5"            # Default is 2
```

## Development

For safer, isolated development, use Docker to run tests in a containerized Ubuntu environment. This prevents any potential side effects on your host system.

```bash
make docker-build
make docker-test
make docker-clean
```

For more commands, run `make help`.

To run the plugin without loading it into tmux all the time, run `./src/git-worktree` in the root of the project to trigger the functionality that would run within the TMUX display-popup.
