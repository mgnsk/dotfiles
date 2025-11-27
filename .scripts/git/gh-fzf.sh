#!/bin/env bash

set -eo pipefail

target="$1"

if [ "$target" != "prs" ] && [ "$target" != "issues" ] && [ "$target" != "code" ]; then
	echo "usage: gh-fzf {prs|issues|code}"
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

	# Github CLI searches words separately.
	# Build a regex string for grep that highlights any of these words.
	# shellcheck disable=SC2001
	query=$(echo "$1" | sed "s/\s\+/|/g")

	# Bold black on yellow background.
	export GREP_COLORS='ms=1;30;103'

	grep --color=always --perl-regexp -i "$query$grepsuffix"
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

function gh-list {
	set -euo pipefail

	repo="$1"
	query="$2"

	issue_pr_list_go_template="$(
		cat <<-'EOF'
			{{- range .}}{{.number | autocolor "yellow"}} {{timeago .createdAt | autocolor "red"}} {{printf "(%s)" .author.login | autocolor "blue"}} {{regexReplaceAllLiteral "[\r\n]+" .title " "}} {{if .stateReason}}{{(printf "(%s: %s)" .state .stateReason) | autocolor "red"}}{{else}}{{(printf "(%s)" .state) | lower | autocolor "red"}}{{end}}{{"\n"}}{{end -}}
		EOF
	)"

	# Handle empty query.
	if [ "$query" == "{q}" ] || [ "$query" == "" ]; then
		gh "${target::-1}" list \
			--state=all \
			--json number,title,state,createdAt,updatedAt,author \
			--jq 'sort_by(.updatedAt) | reverse' |
			gh-tpl --color "$issue_pr_list_go_template"
		exit
	fi

	# Note: we need word splitting - words are passed as separate arguments.
	# shellcheck disable=SC2086
	gh search "$target" \
		--repo "$repo" \
		--sort updated \
		--json number,title,state,createdAt,updatedAt,author \
		--jq 'sort_by(.updatedAt) | reverse' \
		$query |
		gh-tpl --color "$issue_pr_list_go_template"
}

export -f gh-list

function gh-search-code {
	query="$1"

	# Handle empty query.
	if [ "$query" == "{q}" ] || [ "$query" == "" ]; then
		echo "No search term entered!"
		exit
	fi

	RESULTS=$(gh search code --json path,repository,sha,textMatches,url "$query")

	# Store results for preview.
	echo "$RESULTS" >"$tmpdir/code-result.json"

	echo "$RESULTS" | gh-tpl '{{range .}}{{.repository.nameWithOwner}}/{{.path}}{{"\n"}}{{end}}'
}

export -f gh-search-code

function gh-view-code {
	index="$1"
	query="$2"

	# Handle empty query.
	if [ "$query" == "{q}" ] || [ "$query" == "" ]; then
		echo "No search term entered!"
		exit
	fi

	cat "$tmpdir/code-result.json" |
		gh-tpl --jq ".[$index-3] | .matches = [.textMatches[].fragment]" \
			'{{.url}}{{"\n\n"}}{{.matches | join "\n"}}{{"\n"}}' |
		highlight "$query"
}

export -f gh-view-code

function gh-browse-code-result {
	url=$(cat "$tmpdir/code-result.json" |
		gh-tpl --jq ".[$1-3] | .matches = [.textMatches[].fragment]" \
			'{{.url}}')

	xdg-open "$url"
}

export -f gh-browse-code-result

function gh-view {
	set -euo pipefail

	number="$1"
	query="$2"

	if [ "$number" == "" ]; then
		echo "usage: gh-view {number} {query}"
		exit 1
	fi

	commit_list_template="$(
		cat <<-'EOF'
			{{- range .commits}}* {{.oid | trunc 7 | autocolor "yellow"}} {{.messageHeadline}}{{"\n"}}{{end -}}
		EOF
	)"

	if [ "$target" == "prs" ]; then
		GH_FORCE_TTY=$((FZF_PREVIEW_COLUMNS - 4)) gh pr view --comments "$number" |
			highlight "$query"

		gh pr view --json commits "$number" |
			gh-tpl --color "$commit_list_template" |
			highlight "$query"

		echo ""

		gh pr diff --color=always "$number" |
			diff-highlight
	elif [ "$target" == "issues" ]; then
		GH_FORCE_TTY=$((FZF_PREVIEW_COLUMNS - 4)) gh issue view --comments "$number" |
			highlight "$query"
	fi
}

export -f gh-view

function fzf-header {
	grepsuffix=$(cat "$tmpdir/grep_suffix")
	grepmode=""
	if [ "$grepsuffix" == "" ]; then
		grepmode="grep"
	else
		grepmode="passthrough"
	fi

	header=""
	header+="<enter copy number>\n"
	header+="<ctrl-l web>\n"

	if [ "$target" == "prs" ]; then
		header+="<ctrl-o diff>\n"
	fi

	header+="<ctrl-p pinpoint [current: $grepmode]>"

	echo -e "${header}"
}

export -f fzf-header

args=(
	--ansi
	--phony
	--query ''
	--no-sort
	--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down"
	--bind "shift-up:preview-top,shift-down:preview-bottom"
	--bind 'enter:execute(echo {1} | pbcopy)'
	--preview-window=right:50%:wrap
	--style=minimal
	"--header-lines=$(fzf-header | wc -l)"
	--prompt "$target> "
)

if [ "$target" == "prs" ] || [ "$target" == "issues" ]; then
	repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
	# Note: important to use double-quotes throughout, otherwise {q} will be split.
	export FZF_DEFAULT_COMMAND="bash -c \"fzf-header $target; gh-list $repo {q} 2>&1\""

	args+=(
		--bind "change:reload:sleep 0.2; $FZF_DEFAULT_COMMAND || true"
		--preview 'bash -c "gh-view {1} {q}"'
		--bind "ctrl-l:execute-silent(gh browse {1})"
		--bind "ctrl-o:execute(bash -c 'gh pr diff --color=always {1} | diff-highlight | less -R')"
		--bind "ctrl-p:execute-silent(bash -c 'toggle-grep-passthrough')+reload($FZF_DEFAULT_COMMAND)"
	)
elif [ "$target" == "code" ]; then
	# With line numbers.
	# Note: important to use double-quotes throughout, otherwise {q} will be split.
	export FZF_DEFAULT_COMMAND="bash -c \"fzf-header $target; gh-search-code {q} 2>&1\" | nl -ba"

	args+=(
		--bind "change:reload:sleep 0.2; $FZF_DEFAULT_COMMAND || true"
		--with-nth "2.."                                          # Strip line number.
		--preview 'bash -c "gh-view-code {1} {q}"'                # Pass line number.
		--bind "ctrl-l:execute-silent(gh-browse-code-result {1})" # Pass line number.
		--bind "ctrl-p:execute-silent(bash -c 'toggle-grep-passthrough')+reload($FZF_DEFAULT_COMMAND)"
	)
fi

fzf "${args[@]}"
