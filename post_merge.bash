#!/bin/bash
# post-merge hook
original_dir=$(pwd)
# Find the top-level directory of the repository
DOTFILES_DIR=$HOME/dotfiles
HOOKS_DIR=$HOME/dots_hooks
cd $DOTFILES_DIR

# Check if the merge did NOT result in a commit
if [ -f "$DOTFILES_DIR/.git/MERGE_HEAD" ] && [ "$(git rev-parse HEAD)" == "$(git rev-parse ORIG_HEAD)" ]; then
    echo "Fast-forward merge detected, running post-commit actions."
    "$HOOKS_DIR/.dots_hooks/post-commit-merge.bash"
else
    echo "Non-fast-forward merge completed; no additional actions required."
fi

cd $original_dir
