local Github = {}

---@return string
function Github.get_repo()
	local output = vim.fn.system([[gh repo view --json nameWithOwner --template "{{.nameWithOwner}}"]])
	if vim.v.shell_error ~= 0 then
		vim.notify(output, vim.log.levels.ERROR)
		return ""
	end

	return output
end

---@param repo string
---@return string
function Github.create_search_flags(repo)
	return table.concat({
		"--repo",
		string.format([["%s"]], repo),
		"--sort updated",
		"--json number,title,createdAt,author",
		"--template",
		[['{{range .}}{{.number | autocolor "yellow"}} {{timeago .createdAt | autocolor "red"}} {{printf "(%s)" .author.login | autocolor "blue"}} {{.title}}{{"\n"}}{{end}}']],
	}, " ")
end

---@param repo string
---@param q string
---@return string
function Github.cmd_search_prs(repo, q)
	return string.format([[GH_FORCE_TTY='50%%' gh search prs %s "%s"]], Github.create_search_flags(repo), q)
end

---@param repo string
---@param q string
---@return string
function Github.cmd_search_issues(repo, q)
	return string.format([[GH_FORCE_TTY='50%%' gh search issues %s "%s"]], Github.create_search_flags(repo), q)
end

---@param number number
---@return string
function Github.cmd_view_issue(number)
	return string.format([[GH_FORCE_TTY='50%%' gh issue view %s --comments]], number)
end

---@param number number
---@return string
function Github.cmd_view_pr(number)
	return string.format([[GH_FORCE_TTY='50%%' gh pr view %s --comments]], number)
end

---@param number number
---@return string
function Github.cmd_view_pr_comments(number)
	-- TODO: format PR comments like other comments.
	return table.concat({
		string.format([[gh api "repos/{owner}/{repo}/pulls/%s/comments"]], number),
		"--template",
		[['{{range .}}**{{timeago .created_at | autocolor "red"}} {{printf "(%s)" .user.login | autocolor "blue"}}:**{{"\n"}}{{.body}}{{"\n\n\n"}}{{end}}' | glow -s auto]],
	}, " ")
end

return Github
