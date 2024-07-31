#!/bin/bash
original_dir=$(pwd)

# Find the .git directory
GIT_DIR=$(git rev-parse --show-toplevel)


# Create symlinks for hooks
rm "$GIT_DIR/.git/hooks/post-commit"
rm "$GIT_DIR/.git/hooks/post-merge"

cd $original_dir
