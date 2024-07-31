#!/bin/bash

# Find the .git directory
DOTFILES_DIR=$HOME/dotfiles


# Create symlinks for hooks
rm "$DOTFILES_DIR/.git/hooks/post-commit"
rm "$DOTFILES_DIR/.git/hooks/post-merge"

