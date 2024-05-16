#!/usr/bin/env bash

pr_query="$(
	cat <<-'EOF'
		query($name: String!, $owner: String!, $number: Int!) {
			repository(owner: $owner, name: $name) {
				pullRequest(number: $number) {
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
					},
					reviews(last: 100) {
						nodes {
							createdAt,
							url,
							state,
							author {
								login
							},
							minimizedReason,
							body,
							comments(last: 100) {
								nodes {
									createdAt,
									url,
									author {
										login
									},
									minimizedReason,
									position,
									startLine,
									line,
									originalStartLine,
									originalLine,
									diffHunk,
									body
								}
							}
						}
					}
				}
			}
		}
	EOF
)"
export pr_query

pr_jq_template="$(
	cat <<-'EOF'
		.data.repository.pullRequest | .comments = ([
			# Comments.
			(.comments.nodes[]),

			# Reviews.
			(.reviews.nodes[] | select(.body != "")), # Skip placeholder reviews.

			# Review comments.
			(.reviews.nodes[] | . as $review | .comments.nodes[] | . as $comment | .state = $review.state | .diffHunk = ([
				(.diffHunk | split("\n") | . as $arr | to_entries[] |
				# Note: line numbers are for files not diff, can't use them here unless we see all hunks.
				if $comment.originalStartLine == null and $comment.originalLine != null then
					select(.key > ($arr|length)-5)
				else
					select(true)
				end
				| .value)
			] | join("\n")))
		] | sort_by(.createdAt))
	EOF
)"
export pr_jq_template
