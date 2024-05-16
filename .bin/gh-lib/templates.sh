#!/usr/bin/env bash

issue_pr_go_template="$(
	cat <<-'EOF'
		# #{{.number}} {{.title}} ({{.state}})
		## *{{timeago .createdAt}}{{if .author}} {{printf "(%s)" .author.login}}{{end}}:*
		*{{.url}}*

		{{.body}}

		{{range .comments}}
			---

			## *{{timeago .createdAt}}{{if .author}} {{printf "(%s)" .author.login}}{{end}}{{if .state}} {{.state}}{{end}}:*
			*{{.url}}*
			{{if .minimizedReason}}*minimized: {{.minimizedReason}}*{{end}}
			{{if .path}}*path: {{.path}}*{{end}}
			{{if .diffHunk}}{{printf "```diff\n%s\n```" .diffHunk}}{{end}}
			{{.body}}
		{{end}}
	EOF
)"
export issue_pr_go_template

issue_pr_list_go_template='{{range .}}{{.number | autocolor "yellow"}} {{timeago .createdAt | autocolor "red"}} {{printf "(%s)" .author.login | autocolor "blue"}} {{.title | replace "\n" " "}} ({{.state}}){{"\n"}}{{end}}'
export issue_pr_list_go_template
