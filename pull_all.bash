#!/bin/bash

original_dir=$(pwd)

set -e  # Exit on any command failure

# Initialize SSH Agent
eval "$(ssh-agent -s)"  # Start the SSH agent
ssh-add ~/.ssh/id_ed25519  # Add your SSH key; replace id_ed25519 with your key file

# Save the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Function to pull from origin
pull_branch() {
  local remote_branch="$1"
  local branch="${remote_branch#origin/}"  # Remove 'origin/' from the branch name

  echo "Pulling updates for branch: $branch"
  # Check if the branch is already local
  if git rev-parse --verify --quiet "$branch"; then
    git checkout "$branch"
  else
    git checkout -b "$branch" "$remote_branch"
  fi
  if git pull origin "$branch"; then
    echo "Updates pulled successfully for branch: $branch"
  else
    echo "Conflict detected in branch: $branch. Please resolve manually."
    return 1  # Return an error code to indicate a conflict
  fi
}

# Fetch all remote branches and iterate over them
git fetch --all
git branch -r | grep -v '\->' | while read -r remote_branch; do
  if ! pull_branch "$remote_branch"; then
    echo "Stopping the script due to a conflict."
    exit 1  # Exit the script entirely if a conflict occurs
  fi
done

# Checkout the original branch
git checkout "$current_branch"
echo "Returned to the original branch: $current_branch"

# Kill the SSH agent
eval "$(ssh-agent -k)"

cd $original_dir
