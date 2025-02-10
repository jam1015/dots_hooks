#!/bin/sh
# Update the package list file before commit

# Determine the top-level directory of the repo
DOTFILES_DIR=$HOME/dotfiles

# Dump the current package list into the arch-packages file
pacman -Qqe > "$DOTFILES_DIR/arch-packages"

# Add the updated file to the commit
git add "$DOTFILES_DIR/arch-packages"
