#!/usr/bin/env bash

# Scenario: Repository with existing worktrees
mock_git_with_worktrees() {
  # Store worktrees as a delimited string (arrays cannot be exported)
  MOCK_WORKTREES_STR="$*"
  export MOCK_WORKTREES_STR

  git() {
    case "$1 $2" in
      "rev-parse --git-dir")
        echo ".git"
        return 0
        ;;
      "rev-parse --is-bare-repository")
        echo "false"
        return 0
        ;;
      "rev-parse --quiet"|"rev-parse --verify")
        # Branch exists check
        return 0
        ;;
      "worktree list")
        echo "$TEST_DIR main abc123"
        for wt in $MOCK_WORKTREES_STR; do
          echo "$TEST_DIR/../$wt ${wt}-branch def456"
        done
        ;;
      "branch -a")
        echo "  main"
        for wt in $MOCK_WORKTREES_STR; do
          echo "  ${wt}-branch"
        done
        ;;
      *)
        return 0
        ;;
    esac
  }
  export -f git
}

# Scenario: Track worktree add commands
mock_git_capture_worktree_add() {
  git() {
    case "$1" in
      --no-pager)
        # Handle: git --no-pager log
        if [[ "$2" == "log" ]]; then
          echo "abc123 (HEAD -> main) Recent commit"
          echo "def456 Previous commit"
          echo "ghi789 Initial commit"
        fi
        ;;
      worktree)
        if [[ "$2" == "add" ]]; then
          shift 2
          local path="" branch="" new_branch="" commit_ref=""

          while [[ $# -gt 0 ]]; do
            case "$1" in
              -b) shift; new_branch="$1" ;;
              *)
                if [[ -z "$path" ]]; then path="$1"
                elif [[ -z "$new_branch" ]]; then branch="$1"
                else commit_ref="$1"; fi
                ;;
            esac
            shift
          done

          # Save for verification
          cat > /tmp/git_worktree_add.txt <<EOF
PATH=$path
BRANCH=$branch
NEW_BRANCH=$new_branch
COMMIT_REF=$commit_ref
EOF
          mkdir -p "$path"
          return 0
        elif [[ "$2" == "list" ]]; then
          echo "$TEST_DIR main abc123"
        fi
        ;;
      rev-parse)
        case "$2" in
          --git-dir)
            echo ".git"
            return 0
            ;;
          --is-bare-repository)
            echo "false"
            return 0
            ;;
          --quiet|--verify)
            # Check if branch exists - accept main, feature-branch, and existing-branch
            # Handle both "git rev-parse --verify branch" and "git rev-parse --quiet --verify branch"
            local branch_name=""
            if [[ "$3" == "--verify" || "$3" == "--quiet" ]]; then
              branch_name="$4"
            else
              branch_name="$3"
            fi
            if [[ "$branch_name" == "main" || "$branch_name" == "feature-branch" || "$branch_name" == "existing-branch" ]]; then
              return 0
            else
              return 1
            fi
            ;;
        esac
        ;;
      branch)
        echo "  main"
        echo "  feature-branch"
        echo "  existing-branch"
        echo "  remotes/origin/main"
        ;;
      checkout)
        # Handle git checkout (for existing branches) or git checkout -b (for new branches)
        return 0
        ;;
      config|commit)
        return 0
        ;;
      *)
        # Default case: return success for any unhandled git commands
        return 0
        ;;
    esac
  }
  export -f git
}

# Scenario: Track worktree remove commands
mock_git_capture_worktree_remove() {
  git() {
    case "$1 $2" in
      "worktree remove")
        echo "REMOVED=$3" > /tmp/git_worktree_remove.txt
        return 0
        ;;
      "worktree list")
        echo "$TEST_DIR main abc123"
        echo "$TEST_DIR/../feature feature-branch def456"
        ;;
      "rev-parse --git-dir")
        echo ".git"
        return 0
        ;;
      "rev-parse --is-bare-repository")
        echo "false"
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  }
  export -f git
}
