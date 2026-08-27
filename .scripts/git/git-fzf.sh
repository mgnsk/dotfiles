#!/bin/env bash

set -eo pipefail

target="$1"

if [ "$target" != "log" ] && [ "$target" != "reflog" ]; then
	echo "usage: git-fzf {log|reflog}"
	exit 1
fi

set -e

export target

tmpdir=$(mktemp -d)
export tmpdir

function cleanup {
	rm -rf "$tmpdir"
}

trap cleanup EXIT

# Generic key-value state store: each key is a file under $tmpdir, so
# toggle bindings and reload/preview callbacks - each a separate process -
# can share state across the whole fzf session.
#
# Usage:
#   fzf-state <key>          # get: print the current value
#   fzf-state <key> <val>    # set: write <val> for <key>
#   fzf-state <key> <a> <b>  # toggle: set to <b> if currently <a>,
#                            # otherwise set to <a> - used directly in
#                            # --bind so no per-toggle function is needed
function fzf-state {
	key="$1"
	a="${2:-}"
	b="${3:-}"

	if [ -z "$a" ]; then
		cat "$tmpdir/$key" 2>/dev/null
	elif [ -z "$b" ]; then
		echo "$a" >"$tmpdir/$key"
	else
		current=$(cat "$tmpdir/$key" 2>/dev/null)
		newval="$a"
		[ "$current" == "$a" ] && newval="$b"
		echo "$newval" >"$tmpdir/$key"
	fi
}

export -f fzf-state

# Git search mode - default message mode.
# The --grep flag searches from commit messages ("message" state).
# The -G flag searches from diff content ("diff" state).
fzf-state git message

# Grep highlight mode - default passthrough mode.
# When passthrough is enabled, append "|$" to query - grep highlights the matches but shows all lines.
# When passthrough is disabled, grep only shows the matched lines.
fzf-state highlight passthrough

function highlight {
	grepsuffix=""
	[ "$(fzf-state highlight)" == "passthrough" ] && grepsuffix="|$"

	# Bold black on yellow background.
	export GREP_COLORS='ms=1;30;103'

	grep --color=always --perl-regexp -i "$1$grepsuffix"
}

export -f highlight

function git-search {
	set -euo pipefail

	query="$1"

	# Handle empty query.
	if [ "$query" == "{q}" ]; then
		query=""
	fi

	gitflags="-G"
	[ "$(fzf-state git)" == "message" ] && gitflags="--grep"

	if [ "$target" == "log" ]; then
		# Note: we need gitflags unquoted:
		# shellcheck disable=SC2086
		git log --tags HEAD \
			--color --decorate --pretty="format:$GIT_LOG_PRETTY_FORMAT" -i --perl-regexp $gitflags "$query" |
			python3 ~/.scripts/git/relative_date.py
	elif [ "$target" == "reflog" ]; then
		# Note: we need gitflags unquoted:
		# shellcheck disable=SC2086
		git log --reflog --all \
			--color --decorate --pretty="format:$GIT_LOG_PRETTY_FORMAT" -i --perl-regexp $gitflags "$query" |
			python3 ~/.scripts/git/relative_date.py
	fi
}

export -f git-search

function git-view {
	set -euo pipefail

	commit="$1"
	query="$2"

	if [ "$commit" == "" ]; then
		echo "usage: git-view {commit} {query}"
		exit 1
	fi

	# Handle empty query.
	if [ "$query" == "{q}" ]; then
		query=""
	fi

	gitflags="-G"
	[ "$(fzf-state git)" == "message" ] && gitflags="--grep"

	# Note: we need gitflags unquoted:
	# shellcheck disable=SC2086
	git show --show-signature --color -i --perl-regexp $gitflags "$query" "$commit" |
		diff-highlight |
		highlight "$query"
}

export -f git-view

function browse-commit-files {
	set -euo pipefail

	commit="$1"

	if [ "$commit" == "" ]; then
		echo "usage: browse-commit-files {commit}"
		exit 1
	fi

	git diff-tree --no-commit-id --name-status -r "$commit"
}

export -f browse-commit-files

function show-file-diff {
	set -euo pipefail

	commit="$1"
	filepath="$2"

	if [ "$commit" == "" ] || [ "$filepath" == "" ]; then
		echo "usage: show-file-diff {commit} {filepath}"
		exit 1
	fi

	git show --color --format= "$commit" -- "$filepath" |
		diff-highlight
}

export -f show-file-diff

function commit-files-header {
	header=""
	header+="<enter copy filepath>\n"
	header+="<ctrl-o diff>\n"
	header+="<esc back>"

	echo -e "${header}"
}

export -f commit-files-header

function fzf-header {
	gitmode=$(fzf-state git)
	grepmode=$(fzf-state highlight)

	header=""
	header+="<enter copy commit sha>\n"
	header+="<ctrl-e browse files>\n"
	header+="<ctrl-l web>\n"
	header+="<ctrl-o diff>\n"
	header+="<ctrl-f search [current: $gitmode]>\n"
	header+="<ctrl-p pinpoint [current: $grepmode]>"

	echo -e "${header}"
}

export -f fzf-header

# Note: important to use double-quotes throughout, otherwise {q} will be split.
export FZF_DEFAULT_COMMAND="fzf-header; git-search {q} 2>&1"

function browse_commit_files {
	set -euo pipefail

	commit="$1"

	fzf \
		--ansi \
		--header-lines="$(commit-files-header | wc -l)" \
		--bind 'enter:execute(echo {2..} | pbcopy)' \
		--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" \
		--bind "shift-up:preview-top,shift-down:preview-bottom" \
		--bind "ctrl-o:execute(show-file-diff $commit {2..} | less -R)" \
		--bind "esc:abort" \
		--preview "show-file-diff $commit {2..}" \
		--preview-window=right:60%:wrap \
		--style=minimal \
		--prompt "files> " \
		< <(
			commit-files-header
			browse-commit-files "$commit"
		)
}

export -f browse_commit_files

function gh_browse {
	gh browse "$(git rev-parse "$1")"
}

export -f gh_browse

fzf \
	--ansi \
	--phony \
	--query '' \
	--bind "change:reload:sleep 0.2; $FZF_DEFAULT_COMMAND || true" \
	--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" \
	--bind "shift-up:preview-top,shift-down:preview-bottom" \
	--header-lines="$(fzf-header | wc -l)" \
	--bind 'enter:execute(echo {1} | pbcopy)' \
	--bind "ctrl-e:execute(browse_commit_files {1})" \
	--bind "ctrl-l:execute-silent(gh_browse {1})" \
	--bind "ctrl-o:execute(git show --show-signature --color {1} | diff-highlight | less -R)" \
	--bind "ctrl-v:execute(nvim -c 'lua show_commit()' {1})" \
	--bind "ctrl-f:execute-silent(fzf-state git message diff)+reload($FZF_DEFAULT_COMMAND)" \
	--bind "ctrl-p:execute-silent(fzf-state highlight passthrough grep)+reload($FZF_DEFAULT_COMMAND)" \
	--preview 'git-view {1} {q}' \
	--preview-window=right:50%:wrap \
	--style=minimal \
	--prompt "$target> "
