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

function highlight {
	grepsuffix=$(cat "$tmpdir/grep_suffix")

	# Bold black on yellow background.
	export GREP_COLORS='ms=1;30;103'

	grep --color=always --perl-regexp -i "$1$grepsuffix"
}

export -f highlight

# Grep mode - default passthrough mode.
echo "|$" >"$tmpdir/grep_suffix"

# Toggle the grep passthrough mode.
# When passthrough is enabled, append "|$" to query - grep highlights the matches but shows all lines.
# When passthrough is disabled, grep only shows the matched lines.
function toggle-grep-passthrough {
	if grep -q "|" "$tmpdir/grep_suffix"; then
		echo "" >"$tmpdir/grep_suffix"
	else
		echo "|$" >"$tmpdir/grep_suffix"
	fi
}

export -f toggle-grep-passthrough

# Git flags.
# The default --grep flag searches from commit messages.
# The -G flag searches from diff content.
echo "--grep" >"$tmpdir/git_flags"

function toggle-git-mode {
	if grep -q "grep" "$tmpdir/git_flags"; then
		echo "-G" >"$tmpdir/git_flags"
	else
		echo "--grep" >"$tmpdir/git_flags"
	fi
}

export -f toggle-git-mode

function git-search {
	set -euo pipefail

	query="$1"

	# Handle empty query.
	if [ "$query" == "{q}" ]; then
		query=""
	fi

	gitflags=$(cat "$tmpdir/git_flags")

	# Note: we need gitflags unquoted:
	# shellcheck disable=SC2086
	git "$target" --color --decorate --pretty="format:$GIT_LOG_PRETTY_FORMAT" -i --perl-regexp $gitflags "$query"
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

	gitflags=$(cat "$tmpdir/git_flags")

	# Note: we need gitflags unquoted:
	# shellcheck disable=SC2086
	git show --color -i --perl-regexp $gitflags "$query" "$commit" |
		diff-highlight |
		highlight "$query"
}

export -f git-view

function fzf-header {
	gitflags=$(cat "$tmpdir/git_flags")
	gitmode=""
	if [ "$gitflags" == "--grep" ]; then
		gitmode="message"
	elif [ "$gitflags" == "-G" ]; then
		gitmode="diff"
	fi

	grepsuffix=$(cat "$tmpdir/grep_suffix")
	grepmode=""
	if [ "$grepsuffix" == "" ]; then
		grepmode="grep"
	else
		grepmode="passthrough"
	fi

	header=""
	header+="<enter copy commit sha>\n"
	header+="<ctrl-l web>\n"
	header+="<ctrl-o diff>\n"
	header+="<ctrl-f search [current: $gitmode]>\n"
	header+="<ctrl-p pinpoint [current: $grepmode]>"

	echo -e "${header}"
}

export -f fzf-header

# Note: important to use double-quotes throughout, otherwise {q} will be split.
export FZF_DEFAULT_COMMAND="bash -c \"fzf-header; git-search {q} 2>&1\""

fzf \
	--ansi \
	--phony \
	--query '' \
	--bind "change:reload:sleep 0.2; $FZF_DEFAULT_COMMAND || true" \
	--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" \
	--bind "shift-up:preview-top,shift-down:preview-bottom" \
	--header-lines="$(fzf-header | wc -l)" \
	--bind 'enter:execute(echo {1} | pbcopy)' \
	--bind "ctrl-l:execute-silent(git browse {1})" \
	--bind "ctrl-o:execute(bash -c 'git show --color {1} | diff-highlight | less -R')" \
	--bind "ctrl-f:execute-silent(bash -c 'toggle-git-mode')+reload($FZF_DEFAULT_COMMAND)" \
	--bind "ctrl-p:execute-silent(bash -c 'toggle-grep-passthrough')+reload($FZF_DEFAULT_COMMAND)" \
	--preview 'bash -c "git-view {1} {q}"' \
	--preview-window=right:50%:wrap \
	--style=minimal \
	--prompt "$target> "
