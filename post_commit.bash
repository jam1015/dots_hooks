#!/bin/bash
# post-commit hook

# Find the top-level directory of the repository
GIT_DIR=$(git rev-parse --show-toplevel)
PARRALEL_DIR="../dotfiles"
PARRALEL_DIR=$GIT_DIR/$PARRALEL_DIR

# Run post-commit actions for all normal commits
echo "Running post-commit actions for a normal commit."
"$PARRALEL_DIR/post-commit-merge.bash"

