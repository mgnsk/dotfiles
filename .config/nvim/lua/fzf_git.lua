-- Search full patch messages for text.
local function git_log_search(source, prompt)
	return require("fzf-lua").fzf_live(function(q)
		local cmd = table.concat({
			"git",
			source,
			"--all",
			"--color",
			"--decorate",
			"--pretty=format:'%C(yellow)%h %Cred%cr %Cblue(%an)%C(cyan)%d%Creset %s'",
			"-G",
			string.format([["%s"]], q),
		}, " ")
		return cmd
	end, {
		prompt = prompt,
		-- Show the diffs whose patch text contains the query. Pipe through rg to highlight the query.
		preview = "git show --color -G {q} {1} | rg  --colors=match:fg:blue --color=always --passthru {q}",
		actions = {
			["default"] = function(selected)
				vim.fn.setreg("", unpack(selected))
				print(selected)
			end,
		},
	})
end

-- Search for PRs or issues including comments that contain the text.
local function gh_search(command, repo, prompt)
	return require("fzf-lua").fzf_live(function(q)
		local cmd = table.concat({
			"GH_FORCE_TTY='50%'",
			"gh",
			"search",
			command .. "s",
			"--repo",
			string.format([["%s"]], repo),
			"--sort updated",
			"--json number,title,createdAt,author",
			"--template",
			[['{{range .}}{{.number | autocolor "yellow"}} {{timeago .createdAt | autocolor "red"}} {{printf "(%s)" .author.login | autocolor "blue"}} {{.title}}{{"\n"}}{{end}}']],
			string.format([["%s"]], q),
		}, " ")
		return cmd
	end, {
		prompt = prompt,
		fzf_opts = {
			["--preview"] = {
				type = "cmd",
				fn = function(items)
					local number = string.match(unpack(items), "%d+")

					local target = ""

					if command == "pr" then
						target = "pulls"
					elseif command == "issue" then
						target = "issues"
					end

					local cmd = table.concat({
						-- First command.
						"GH_FORCE_TTY='50%'",
						"gh",
						command,
						"view",
						number,
						"--comments",
						";",

						-- Second command.
						"GH_FORCE_TTY='50%'",
						string.format([[gh api "repos/{owner}/{repo}/%s/%s/comments"]], target, number),
						"--template",
						[['{{range .}}{{timeago .created_at | autocolor "red"}} {{printf "(%s)" .user.login | autocolor "blue"}}: {{.body}}{{"\n"}}{{end}}']],
					}, " ")

					return cmd
				end,
			},
		},
		actions = {
			["default"] = function(selected)
				vim.fn.setreg("", unpack(selected))
				print(selected)
			end,
		},
	})
end

local function get_repo()
	local output = vim.fn.system([[gh repo view --json nameWithOwner --template "{{.nameWithOwner}}"]])
	if vim.v.shell_error ~= 0 then
		vim.notify(output, vim.log.levels.ERROR, { title = "gh" })
		return ""
	end

	return output
end

local M = {}

function M.fzf_git_log()
	return git_log_search("log", "git log> ")
end

function M.fzf_git_reflog()
	return git_log_search("reflog", "git reflog> ")
end

function M.fzf_gh_prs()
	local repo = get_repo()
	return gh_search("pr", repo, "Pull requests> ")
end

function M.fzf_gh_issues()
	local repo = get_repo()
	return gh_search("issue", repo, "Issues> ")
end

function M.setup()
	vim.api.nvim_create_user_command("FzfGitLog", M.fzf_git_log, { desc = "FZF git log" })
	vim.api.nvim_create_user_command("FzfGitReflog", M.fzf_git_reflog, { desc = "FZF git reflog" })
	vim.api.nvim_create_user_command("FzfPullRequests", M.fzf_gh_prs, { desc = "FZF pull requests" })
	vim.api.nvim_create_user_command("FzfIssues", M.fzf_gh_issues, { desc = "FZF issues" })
end

return M
