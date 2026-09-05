#!/bin/env bash

set -eu

HM_OUTPUT=".#homeConfigurations.$(id -un).activationPackage"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "Not inside a git repository, aborting." >&2
	exit 1
fi

if ! git diff --quiet -- flake.lock || ! git diff --cached --quiet -- flake.lock; then
	echo "flake.lock has uncommitted changes, commit or stash them first so a rejected update can be cleanly reverted." >&2
	exit 1
fi

is_nixpkgs_input() {
	nix flake metadata --json 2>/dev/null |
		jq -e --arg n "$1" '.locks.nodes[$n].original | .owner == "nixos" and .repo == "nixpkgs"' >/dev/null
}

confirm_or_abort() {
	local reply
	read -rp "Continue? [Y/n] " reply
	case "$reply" in
	[nN]*)
		echo "Aborting update, reverting flake.lock."
		git checkout -- flake.lock
		exit 1
		;;
	esac
}

# Print the diff for one relative path between two source trees, handling
# the file being added or removed by the update.
show_file_diff() {
	local old_root="$1" new_root="$2" rel="$3"
	local old_file="$old_root/$rel" new_file="$new_root/$rel"

	if [[ -e "$old_file" && -e "$new_file" ]]; then
		git diff --no-index -- "$old_file" "$new_file" || true
	elif [[ -e "$new_file" ]]; then
		echo "Added: $rel"
		git diff --no-index -- /dev/null "$new_file" || true
	elif [[ -e "$old_file" ]]; then
		echo "Removed: $rel"
		git diff --no-index -- "$old_file" /dev/null || true
	else
		return 1
	fi
}

# Positions (from closurePositions.<input>) as "root-relative" paths, with
# the trailing ":LINE" stripped, one per line.
relative_positions() {
	local store_path="$1" input="$2"
	nix eval --impure --json ".#closurePositions.$input" 2>/dev/null |
		jq -r --arg prefix "$store_path/" '.[] | .[($prefix | length):] | sub(":[0-9]+$"; "")'
}

review_nixpkgs_input() {
	local input="$1" old_store_path="$2" new_store_path="$3"

	if ! nix eval --impure --json ".#packageSets.$input" >/dev/null 2>&1; then
		echo "No packageSets.$input flake output, skipping per-file diff for $input."
		return
	fi

	local old_positions new_positions
	old_positions=$(relative_positions "$old_store_path" "$input")
	new_positions=$(relative_positions "$new_store_path" "$input")

	local rel
	while IFS= read -r rel; do
		[[ -z "$rel" ]] && continue
		if diff -q "$old_store_path/$rel" "$new_store_path/$rel" >/dev/null 2>&1; then
			continue
		fi
		show_file_diff "$old_store_path" "$new_store_path" "$rel"
		confirm_or_abort
	done < <(printf '%s\n%s\n' "$old_positions" "$new_positions" | sort -u)
}

review_repo_input() {
	local old_store_path="$1" new_store_path="$2"

	local status path rel
	while IFS=$'\t' read -r status path; do
		[[ -z "$path" ]] && continue
		if [[ "$path" == "$old_store_path/"* ]]; then
			rel="${path#"$old_store_path"/}"
		elif [[ "$path" == "$new_store_path/"* ]]; then
			rel="${path#"$new_store_path"/}"
		else
			continue
		fi
		show_file_diff "$old_store_path" "$new_store_path" "$rel"
		confirm_or_abort
	done < <(git diff --no-index --name-status "$old_store_path" "$new_store_path" 2>/dev/null || true)
}

# Determine which inputs actually have an update available, so the
# selection prompt doesn't offer inputs that would be a no-op. Each input is
# checked with its own `nix flake update` call, not one bulk call for all of
# them: if any single input hits a flaky fetch (e.g. a GitHub API rate
# limit), a bulk update silently leaves the *entire* lock file unchanged
# instead of just that one input, which would make this check under-report.
mapfile -t ALL_INPUTS < <(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes.root.inputs | keys[]')

SCRATCH_LOCK=$(mktemp)
trap 'rm -f "$SCRATCH_LOCK"' EXIT

UPDATABLE_INPUTS=()
for input in "${ALL_INPUTS[@]}"; do
	cp flake.lock "$SCRATCH_LOCK"
	nix flake update --output-lock-file "$SCRATCH_LOCK" "$input" >/dev/null

	old_locked=$(jq -c --arg n "$input" '.nodes[$n].locked' flake.lock)
	new_locked=$(jq -c --arg n "$input" '.nodes[$n].locked' "$SCRATCH_LOCK")
	[[ "$old_locked" != "$new_locked" ]] && UPDATABLE_INPUTS+=("$input")
done

rm -f "$SCRATCH_LOCK"
trap - EXIT

if [[ ${#UPDATABLE_INPUTS[@]} -eq 0 ]]; then
	echo "All inputs are already up to date."
	exit 0
fi

mapfile -t INPUTS < <(printf '%s\n' "${UPDATABLE_INPUTS[@]}" | fzf --multi)

if [[ ${#INPUTS[@]} -eq 0 ]]; then
	echo "No inputs selected, aborting."
	exit 1
fi

OLD_STORE_PATH=$(nix build --impure --show-trace --no-link --print-out-paths "$HM_OUTPUT")

for input in "${INPUTS[@]}"; do
	echo "Updating $input"

	old_store_path=$(nix flake archive --json | jq -r --arg input "$input" '.inputs[$input].path')
	nix flake update "$input"
	new_store_path=$(nix flake archive --json | jq -r --arg input "$input" '.inputs[$input].path')

	if is_nixpkgs_input "$input"; then
		review_nixpkgs_input "$input" "$old_store_path" "$new_store_path"
	else
		review_repo_input "$old_store_path" "$new_store_path"
	fi
done

# Build the new output and get its store path.
NEW_STORE_PATH=$(nix build --impure --show-trace --no-link --print-out-paths "$HM_OUTPUT")

# Show package version changes.
nix store diff-closures "$OLD_STORE_PATH" "$NEW_STORE_PATH"
