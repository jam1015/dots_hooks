#!/bin/bash
# post-merge hook
original_dir=$(pwd)
# Find the top-level directory of the repository
git_cmd="git"
GIT_DIR=$($git_cmd rev-parse --show-toplevel)
PARRALEL_DIR="../dotfiles"
GIT_DIR=$GIT_DIR/$PARRALEL_DIR

# Check if the merge did NOT result in a commit
if [ -f "$GIT_DIR/.git/MERGE_HEAD" ] && [ "$(git rev-parse HEAD)" == "$(git rev-parse ORIG_HEAD)" ]; then
    echo "Fast-forward merge detected, running post-commit actions."
    "$PARRALEL_DIR/.dots_hooks/post-commit-merge.bash"
else
    echo "Non-fast-forward merge completed; no additional actions required."
fi

cd $original_dir
