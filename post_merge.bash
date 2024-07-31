#!/bin/bash
# post-merge hook
# Find the top-level directory of the repository
DOTFILES_DIR=$HOME/dotfiles
HOOKS_DIR=$HOME/dots_hooks
GIT_CMD="git -C $DOTFILES_DIR"

# Check if the merge did NOT result in a commit
if [ "$($GIT_CMD rev-parse HEAD)" == "$($GIT_CMD rev-parse ORIG_HEAD)" ]; then
    echo "Fast-forward merge detected, running post-commit actions."
  if [[ -x "${HOOKS_DIR}/post-commit-merge.bash" ]]; then
      "${HOOKS_DIR}/post-commit-merge.bash"
  else
      echo "Error: Hook script not found or not executable."
  fi
else
    echo "Non-fast-forward merge completed; no additional actions required."
fi

