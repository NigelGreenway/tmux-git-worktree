!#/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bind-key C-g display-popup -E -w 80% -h 60% -d "#{pane_current_path}" "$CURRENT_DIR/src/main"
