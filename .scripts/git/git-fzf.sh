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

	if [ "$target" == "log" ]; then
		# Note: we need gitflags unquoted:
		# shellcheck disable=SC2086
		git log \
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

	gitflags=$(cat "$tmpdir/git_flags")

	# Note: we need gitflags unquoted:
	# shellcheck disable=SC2086
	git show --color -i --perl-regexp $gitflags "$query" "$commit" |
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
		--bind "ctrl-o:execute(show-file-diff $commit {2..})" \
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
	--bind "ctrl-o:execute(git show --color {1} | diff-highlight | less -R)" \
	--bind "ctrl-v:execute(nvim -c 'lua show_commit()' {1})" \
	--bind "ctrl-f:execute-silent(toggle-git-mode)+reload($FZF_DEFAULT_COMMAND)" \
	--bind "ctrl-p:execute-silent(toggle-grep-passthrough)+reload($FZF_DEFAULT_COMMAND)" \
	--preview 'git-view {1} {q}' \
	--preview-window=right:50%:wrap \
	--style=minimal \
	--prompt "$target> "
