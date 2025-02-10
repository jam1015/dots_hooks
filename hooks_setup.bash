#!/bin/bash

# Find the .git directory
DOTFILES_DIR=$HOME/dotfiles
HOOKS_DIR=$HOME/dots_hooks

# Ensure the hooks directory exists
mkdir -p "$DOTFILES_DIR/.git/hooks"

# Create symlinks for hooks
ln -sf "$HOOKS_DIR/post_commit.bash" "$DOTFILES_DIR/.git/hooks/post-commit"
ln -sf "$HOOKS_DIR/post_merge.bash" "$DOTFILES_DIR/.git/hooks/post-merge"
ln -sf "$HOOKS_DIR/pre_commit.bash" "$DOTFILES_DIR/.git/hooks/pre-commit

echo "setup hooks"
