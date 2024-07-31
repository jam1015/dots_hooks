#!/bin/bash
# post-commit hook

# Find the top-level directory of the repository
DOTFILES_DIR=$HOME/dotfiles
HOOKS_DIR=$HOME/dots_hooks

# Run post-commit actions for all normal commits
echo "Running post-commit actions for a normal commit."
"$HOOKS_DIR/post-commit-merge.bash"

