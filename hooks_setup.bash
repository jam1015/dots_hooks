#!/bin/bash

# Find the .git directory
GIT_DIR=$(git rev-parse --show-toplevel)
PARRALEL_DIR=$GIT_DIR/../dotfiles

# Ensure the hooks directory exists
mkdir -p "$GIT_DIR/.git/hooks"

# Create symlinks for hooks
ln -sf "$PARRALEL_DIR/post_commit.bash" "$GIT_DIR/.git/hooks/post-commit"
ln -sf "$PARRALEL_DIR/post_merge.bash" "$GIT_DIR/.git/hooks/post-merge"

