#!/bin/env bash

set -eu

# Local main branch.
main=$(git branch -l main master --format '%(refname:short)')

if [ -z "$main" ]; then
	echo "Error: Could not find a 'main' or 'master' branch." >&2
	exit 1
fi

export main

function branch-search {
	git branch --format="%(refname:short)" --sort=-committerdate
}

export -f branch-search

function branch-view {
	export GIT_LOG_PRETTY_FORMAT='%C(yellow)%h%Creset%x1f%ct%x1f%Creset%s%x1f%Cblue<%an>'

	git log \
		--color --decorate --pretty="format:$GIT_LOG_PRETTY_FORMAT" "$main..$1" |
		python3 ~/.scripts/git/relative_date.py

	echo ""

	# Note: special three-dot syntax: https://stackoverflow.com/a/20809283
	git diff --color "$main...$1" | diff-highlight
}

export -f branch-view

function fzf-header {
	header=""
	header+="<switch>\n"
	header+="<ctrl-o diff>\n"
	header+="<delete delete>"

	echo -e "${header}"
}

export -f fzf-header

# Note: important to use double-quotes throughout, otherwise {q} will be split.
export FZF_DEFAULT_COMMAND="bash -c \"fzf-header; branch-search {q} 2>&1\""

fzf \
	--ansi \
	--query '' \
	--accept-nth=1 \
	--bind "change:reload:sleep 0.2; $FZF_DEFAULT_COMMAND || true" \
	--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" \
	--bind "shift-up:preview-top,shift-down:preview-bottom" \
	--header-lines="$(fzf-header | wc -l)" \
	--bind 'enter:execute(git switch {1})+abort' \
	--bind "ctrl-o:execute(bash -c 'branch-view {1} | less -R')" \
	--bind "delete:execute-silent(git branch -D {1})+reload($FZF_DEFAULT_COMMAND)" \
	--preview 'bash -c "branch-view {1}"' \
	--preview-window=right:50%:wrap \
	--style=minimal \
	--prompt "branch> "
