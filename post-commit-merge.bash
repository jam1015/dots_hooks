#!/bin/bash
original_dir=$(pwd)

# Initialize depth level
depth=0

frame_echo() {
	local arg="$1"
	local line="========================================================="
	local indent=$(printf "%*s" $depth "")
	echo "${indent}${line}"
	echo "${indent}${arg}"
	echo "${indent}${line}"
}

DOTFILES_DIR=$HOME/dotfiles
HOOKS_DIR=$HOME/dots_hooks
GIT_CMD="git -C $DOTFILES_DIR"

[ -f "$DOTFILES_DIR/hooks/post-commit" ] && rm "$DOTFILES_DIR/hooks/post-commit"
[ -f "$DOTFILES_DIR/hooks/post-merge" ] && rm "$DOTFILES_DIR/hooks/post-merge"

set -e
# Source configuration
source "$HOOKS_DIR/config.bash"
echo $DOTSREBASESTRATEGY

if [[ -n "$RUN" ]]; then

	original_display=$DISPLAY

	# Add your SSH key and set a timeout (in seconds)
	unset DISPLAY
	if [[ -n "$DOTSPUSH" || -n "$DOTSPULL" ]]; then
		eval "$(ssh-agent -s)"
		ssh-add -t 3600 ~/.ssh/id_ed25519
                trap "kill $SSH_AGENT_PID" EXIT
	fi

	# Function to check if a branch exists locally
	branch_exists() {
		if $GIT_CMD show-ref --verify --quiet "refs/heads/$1"; then
			return 0 # branch exists
		else
			return 1 # branch does not exist
		fi
	}

	rebase_or_merge() {
		local source_branch=$1
		local target_branch=$2
		local rebased_or_merged=""

		local reapply_cherry_picks=""
		if [[ -n "$REAPPLYCHERRYPICKS" ]]; then
			reapply_cherry_picks="--reapply-cherry-picks"
		else
			reapply_cherry_picks=""
		fi

		# Determine rebase strategy from configuration; note that this is counterintuitive
		local rebase_strategy=""
		local merge_strategy=""
		case "$DOTSREBASESTRATEGY" in
		"theirs")
			rebase_strategy="-X ours"
			;;
		"ours")
			rebase_strategy="-X theirs"
			;;
		esac

		case "$DOTSMERGESTRATEGY" in
		"theirs")
			merge_strategy="-X theirs"
			;;
		"ours")
			merge_strategy="-X ours"
			;;
		esac
		if [[ "$source_branch" == "$target_branch" ]]; then
			frame_echo "Source and target branches are the same: $source_branch. Skipping rebase/merge."
			return 0
		fi

		if [[ -n "$DOTSTRYREBASE" ]]; then
			if ! $GIT_CMD rebase "$reapply_cherry_picks" "$rebase_strategy" "${source_branch}"; then
				frame_echo "Rebase from ${source_branch} to ${target_branch} failed. Handle conflicts manually."
				# Removed git rebase --abort to allow manual conflict resolution
			else
				rebased_or_merged="true"
				frame_echo "Rebase successful."
			fi
		else
			frame_echo "DOTSTRYREBASE is not set. Proceeding with merge."
			if ! $GIT_CMD merge "$merge_strategy" "${source_branch}"; then
				frame_echo "Merge from ${source_branch} to ${target_branch} failed. Handle merge conflicts if any."
			else
				rebased_or_merged="true"
				frame_echo "Merge successful."
			fi
		fi

		if [[ -n "$rebased_or_merged" && -n "$DOTSPULL" ]]; then
			if ! $GIT_CMD pull origin "${target_branch}"; then
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
		if [[ "$($GIT_CMD rev-parse --abbrev-ref HEAD)" != "${target_branch}" ]]; then
			frame_echo "Checking out target: ${target_branch}"
			$GIT_CMD checkout "${target_branch}"
		fi

		if [[ -n "$DOTSPULL" ]]; then
			# Pull the latest changes from the origin of the target branch
			if ! $GIT_CMD pull origin "${target_branch}"; then
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
			$GIT_CMD push origin "${target_branch}"
		else
			frame_echo "DOTSPUSH is not set. Skipping push."
		fi

		# Skip checkout if source and target branches are the same
		if [[ "$($GIT_CMD rev-parse --abbrev-ref HEAD)" != "${target_branch}" ]]; then
			frame_echo "Checking ${source_branch} back out."
			$GIT_CMD checkout "${source_branch}"
		fi

		frame_echo "Completed post commit/merge logic: Source: ${source_branch} | Target: ${target_branch}"
	}

	# This function now just prepares the queue and processes it
	merge_switch() {
		# Declare an associative array to map branches to their respective targets
		declare -A branch_map
		branch_map["master"]="computer phone"
		branch_map["computer"]="linux mac"
		branch_map["phone"]="termux"
		branch_map["linux"]="arch"
		branch_map["arch"]="jmtp endeavour"
		branch_map["endeavour"]="mbp fw"
		branch_map["mac"]=""
		branch_map["fw"]=""
		branch_map["termux"]=""
		branch_map["jmtp"]=""
		branch_map["mbp"]=""

		# Start with the current branch
		local current_branch=$($GIT_CMD rev-parse --abbrev-ref HEAD)
		local original_branch=$current_branch
		local branches_to_process=($current_branch)
		local next_level_branches=()

		while [ ${#branches_to_process[@]} -ne 0 ]; do
			for branch in "${branches_to_process[@]}"; do
				# Increase depth level
				depth=$((depth + 1))
				# Extract targets for the current branch
				local targets=(${branch_map[$branch]})
				for target in "${targets[@]}"; do
					merge_to "$branch" "$target"
					next_level_branches+=("$target")
				done
				# Decrease depth level
				depth=$((depth - 1))
			done
			# Prepare the next level of branches
			branches_to_process=("${next_level_branches[@]}")
			next_level_branches=()
		done

		$GIT_CMD checkout "$original_branch"
	}

	merge_switch

	export DISPLAY=$original_display

	if [[ -n "$STOW" ]]; then
		cd "$($GIT_CMD rev-parse --show-toplevel)"
		# Run stow for all directories within the dotfiles repo
		stow --target="$HOME" *
		# Change back to the original directory
		cd "$original_dir"
	fi

	ln -sf "$HOOKS_DIR/post_commit.bash" "$DOTFILES_DIR/.git/hooks/post-commit"
	ln -sf "$HOOKS_DIR/post_merge.bash" "$DOTFILES_DIR/.git/hooks/post-merge"

else
	frame_echo "Hooks are disabled."
fi
