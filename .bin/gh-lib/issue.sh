#!/usr/bin/env bash

issue_query="$(
	cat <<-'EOF'
		query($name: String!, $owner: String!, $number: Int!) {
			repository(owner: $owner, name: $name) {
				issue(number: $number) {
					number,
					title,
					url,
					createdAt,
					state,
					author {
						login
					},
					body,
					comments(last: 100) {
						nodes {
							createdAt,
							url,
							author {
								login
							},
							minimizedReason,
							body
						}
					}
				}
			}
		}
	EOF
)"
export issue_query

issue_jq_template="$(
	cat <<-'EOF'
		.data.repository.issue | .comments = .comments.nodes
	EOF
)"
export issue_jq_template
