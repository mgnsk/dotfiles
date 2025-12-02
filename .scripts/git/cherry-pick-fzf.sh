#!/bin/env bash

set -eu

function highlight {
	# Grep mode - default passthrough mode.
	grepsuffix="|$"

	# Bold black on yellow background.
	export GREP_COLORS='ms=1;30;103'

	grep --color=always --perl-regexp -i "$1$grepsuffix"
}

export -f highlight

# List commits not in current branch. Filter commit messages by query.
function git-search {
	current=$(git branch --show-current)
	query="$1"

	# Handle empty query.
	if [ "$query" == "{q}" ]; then
		query=""
	fi

	# Show commits from all branches that are not merged into the current branch.
	# --no-merges: exclude merge commits, common for cherry-picking.
	# --branches: consider all local branches as starting points.
	# --not "$current": exclude commits reachable from the current branch.
	git log --color --decorate --pretty="format:$GIT_LOG_PRETTY_FORMAT" \
		--no-merges \
		--branches \
		--not "$current" \
		-i --perl-regexp --grep "$query"
}

export -f git-search

# View commit diff against current branch.
function git-view {
	branch=$(git branch --show-current)
	commit="$1"

	if [ "$commit" == "" ]; then
		echo "usage: git-view {commit}"
		exit 1
	fi

	git show --color "$branch..$commit" |
		diff-highlight |
		highlight "$query"
}

export -f git-view

function fzf-header {
	header=""
	header+="<enter cherry pick>\n"
	header+="<ctrl-l web>\n"
	header+="<ctrl-o diff>"

	echo -e "${header}"
}

export -f fzf-header

# Note: important to use double-quotes throughout, otherwise {q} will be split.
export FZF_DEFAULT_COMMAND="bash -c \"fzf-header; git-search {q} 2>&1\""

fzf \
	--ansi \
	--phony \
	--query '' \
	--header-lines="$(fzf-header | wc -l)" \
	--bind "change:reload:sleep 0.2; $FZF_DEFAULT_COMMAND || true" \
	--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" \
	--bind "shift-up:preview-top,shift-down:preview-bottom" \
	--bind 'enter:execute(git cherry-pick -x {1})' \
	--bind "ctrl-l:execute-silent(git browse {1})" \
	--bind "ctrl-o:execute(bash -c 'git show --color {1} | diff-highlight | less -R')" \
	--preview 'bash -c "git-view {1}"' \
	--preview-window=right:50%:wrap \
	--style=minimal \
	--prompt "Select commit to cherry pick"
