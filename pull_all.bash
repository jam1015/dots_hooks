#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
set -o pipefail  # Exit if any command in a pipeline fails

# Save the original directory and branch
original_dir=$(pwd)
cd "$HOME/dotfiles"
GIT_CMD="git -C $HOME/dotfiles"
current_branch=$($GIT_CMD rev-parse --abbrev-ref HEAD)

# Function to clean up before exit
cleanup() {
  echo "Cleaning up..."
  # Return to the original branch if it exists
  if $GIT_CMD rev-parse --verify --quiet "$current_branch" >/dev/null; then
    $GIT_CMD checkout "$current_branch"
    echo "Returned to the original branch: $current_branch"
  fi
  # Kill the SSH agent if it was started by this script
  if [[ -n "$SSH_AGENT_PID" ]]; then
    kill "$SSH_AGENT_PID" >/dev/null 2>&1 || true
  fi
  cd "$original_dir"
}
trap cleanup EXIT

# Initialize SSH Agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
  eval "$(ssh-agent -s)"
  # Add SSH key; check if the key exists
  SSH_KEY="$HOME/.ssh/id_ed25519"
  if [[ -f "$SSH_KEY" ]]; then
    ssh-add "$SSH_KEY"
  else
    echo "SSH key $SSH_KEY not found."
    exit 1
  fi
else
  echo "SSH agent is already running."
fi

# Function to pull and rebase a branch
pull_and_rebase_branch() {
  local remote_branch="$1"
  local branch="${remote_branch#origin/}"

  echo "Updating branch: $branch"

  # Check if the branch is already local
  if $GIT_CMD rev-parse --verify --quiet "$branch" >/dev/null; then
    $GIT_CMD checkout "$branch"
  else
    $GIT_CMD checkout -b "$branch" "$remote_branch"
  fi

  # Pull and rebase; handle conflicts
  if ! $GIT_CMD pull --rebase origin "$branch"; then
    echo "Conflict detected in branch: $branch. Please resolve manually."
    # Return to the original branch before exiting
    exit 1
  else
    echo "Successfully rebased branch: $branch"
  fi
}

# Fetch all remote branches
echo "Fetching all remote branches..."
$GIT_CMD fetch --all

# Get list of remote branches excluding HEAD
remote_branches=$($GIT_CMD for-each-ref --format='%(refname:strip=3)' refs/remotes/origin | grep -v '^HEAD$')

# Iterate over remote branches
for remote_branch in $remote_branches; do
  pull_and_rebase_branch "origin/$remote_branch"
done
