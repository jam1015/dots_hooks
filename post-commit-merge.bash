#!/bin/bash
original_dir=$(pwd)

frame_echo() {
	local arg="$1"
	local line="========================================================="
	echo "$line"
	echo "$arg"
	echo "$line"
}

# Define git command for convenience
git_cmd="git"

DOTFILES_DIR=$HOME/dotfiles
HOOKS_DIR=$HOME/dots_hooks

cd $DOTFILES_DIR

rm "$DOTFILES_DIR/hooks/post-commit"
rm "$DOTFILES_DIR/hooks/post-merge"

set -e
# Source configuration
source "$HOOKS_DIR/config.bash"

if [[ -n "$RUN" ]]; then
	if [[ -n "$DOTSPUSH" || -n "$DOTSPULL" ]]; then
		eval "$(ssh-agent -s)"
	fi

	original_display=$DISPLAY

	# Add your SSH key and set a timeout (in seconds)
	unset DISPLAY
	if [[ -n "$DOTSPUSH" || -n "$DOTSPULL" ]]; then
		ssh-add -t 3600 ~/.ssh/id_ed25519
		eval "$(ssh-agent -s)"
	fi

	# Function to check if a branch exists locally
	branch_exists() {
		if $git_cmd show-ref --verify --quiet "refs/heads/$1"; then
			return 0 # branch exists
		else
			return 1 # branch does not exist
		fi
	}

	rebase_or_merge() {
		local source_branch=$1
		local target_branch=$2
		local rebased=""

		local reapply_cherry_picks=""
		if [[ -n "$REAPPLYCHERRYPICKS" ]]; then
			reapply_cherry_picks="--reapply-cherry-picks"
		else
			reapply_cherry_picks=""
		fi

		# Determine rebase strategy from configuration
		local rebase_strategy=""
		case "$DOTSREBASESTRATEGY" in
		"theirs")
			rebase_strategy="-X theirs"
			;;
		"ours")
			rebase_strategy="-X ours"
			;;
		esac

		if [[ "$source_branch" == "$target_branch" ]]; then
			frame_echo "Source and target branches are the same: $source_branch. Skipping rebase/merge."
			return 0
		fi

		if [[ -n "$DOTSTRYREBASE" ]]; then
			if ! $git_cmd rebase $reapply_cherry_picks $rebase_strategy "${source_branch}"; then
				frame_echo "Rebase from ${source_branch} to ${target_branch} failed. Handle conflicts manually."
				# Removed git rebase --abort to allow manual conflict resolution
			else
				rebased="true"
				frame_echo "Rebase successful."
			fi
		else
			frame_echo "DOTSTRYREBASE is not set. Proceeding with merge."
			if ! $git_cmd merge "${source_branch}"; then
				frame_echo "Merge from ${source_branch} to ${target_branch} failed. Handle merge conflicts if any."
			else
				frame_echo "Merge successful."
			fi
		fi

		if [[ -n "$rebased" && -n "$DOTSPULL" ]]; then
			if ! $git_cmd pull origin "${target_branch}"; then
				frame_echo "Pull from origin ${target_branch} failed. Resolve any issues and retry."
			else
				frame_echo "Second pull of ${target_branch} after rebase successful."
			fi
		fi

		return 0
	}

	merge_to() {
		local source_branch=$1
		local target_branch=$2

		if ! branch_exists "${target_branch}"; then
			frame_echo "Branch ${target_branch} does not exist on this system."
			return 1
		fi

		frame_echo "Starting post commit/merge logic: Source: ${source_branch} | Target: ${target_branch}"

		# Switch to the target branch only if it's not the current branch
		if [[ "$($git_cmd rev-parse --abbrev-ref HEAD)" != "${target_branch}" ]]; then
			frame_echo "Checking out target: ${target_branch}"
			$git_cmd checkout "${target_branch}"
		fi

		if [[ -n "$DOTSPULL" ]]; then
			# Pull the latest changes from the origin of the target branch
			if ! $git_cmd pull origin "${target_branch}"; then
				frame_echo "Pull from origin ${target_branch} failed. Resolve any issues and retry."
				return 1
			fi
			frame_echo "Pull from ${target_branch} successful. Starting rebase or merge from ${source_branch}."
		else
			frame_echo "DOTSPULL is not set. Skipping pull."
		fi

		# Attempt to rebase, and fall back to merge if rebase fails
		if ! rebase_or_merge "${source_branch}" "${target_branch}"; then
			frame_echo "merge or rebase failed"
			return 1
		fi

		if [[ -n "$DOTSPUSH" ]]; then
			frame_echo "Pushing to origin."
			$git_cmd push origin "${target_branch}"
		else
			frame_echo "DOTSPUSH is not set. Skipping push."
		fi

		# Skip checkout if source and target branches are the same
		if [[ "$($git_cmd rev-parse --abbrev-ref HEAD)" != "${source_branch}" ]]; then
			frame_echo "Checking ${source_branch} back out."
			$git_cmd checkout "${source_branch}"
		fi

		frame_echo "Completed post commit/merge logic: Source: ${source_branch} | Target: ${target_branch}"
	}

	# This function now just prepares the queue and processes it
	merge_switch() {
		# Declare an associative array to map branches to their respective targets
		declare -A branch_map
		branch_map["master"]="linux mac termux"
		branch_map["linux"]="arch endeavour"
		branch_map["arch"]="jmtp"
		branch_map["endeavour"]="mbp fw"
		branch_map["mac"]=""
		branch_map["fw"]=""
		branch_map["termux"]=""
		branch_map["jmtp"]=""
		branch_map["mbp"]=""

		# Start with the current branch
		local current_branch
		current_branch=$($git_cmd rev-parse --abbrev-ref HEAD)
		local original_branch=$current_branch
		local branches_to_process=($current_branch)
		local next_level_branches=()

		while [ ${#branches_to_process[@]} -ne 0 ]; do
			for branch in "${branches_to_process[@]}"; do
				# Extract targets for the current branch
				local targets=(${branch_map[$branch]})
				for target in "${targets[@]}"; do
					merge_to "$branch" "$target"
					next_level_branches+=("$target")
				done
			done
			# Prepare the next level of branches
			branches_to_process=("${next_level_branches[@]}")
			next_level_branches=()
		done

		$git_cmd checkout "$original_branch"
	}

	merge_switch

	export DISPLAY=$original_display

	if [[ -n "$STOW" ]]; then
		cd "$(git rev-parse --show-toplevel)"
		# Run stow for all directories within the dotfiles repo
		stow --target="$HOME" *
		# Change back to the original directory
		cd "$original_dir"
	fi

	ln -sf "$HOOKS_DIR/post_commit.bash" "$DOTFILES_DIR/hooks/post-commit"
	ln -sf "$HOOKS_DIR/post_merge.bash" "$DOTFILES_DIR/hooks/post-merge"

else
	frame_echo "Hooks are disabled."
fi

cd "$original_dir"
