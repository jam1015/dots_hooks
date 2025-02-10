#!/bin/sh
# Update the package list file before commit

DOTFILES_DIR=$HOME/dotfiles

if command -v pacman >/dev/null 2>&1; then
    # pacman exists: Dump the current package list into the arch-packages file
    pacman -Qqtte  | tr '\n' ' ' > "$DOTFILES_DIR/arch-packages"
    # Add the updated file to the commit
    git add "$DOTFILES_DIR/arch-packages"
else
    # pacman does not exist: Notify and skip updating the package list
    echo "pacman not found, skipping arch-packages update."
fi
