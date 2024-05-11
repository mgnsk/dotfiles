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

local M = {}

function M.fzf_git_log()
	return git_log_search("log", "git log> ")
end

function M.fzf_git_reflog()
	return git_log_search("reflog", "git reflog> ")
end

function M.fzf_gh_prs()
	local gh = require("github")
	local repo = gh.get_repo()

	return require("fzf-lua").fzf_live(function(q)
		return gh.cmd_search_prs(repo, q)
	end, {
		prompt = "Pull requests> ",
		fzf_opts = {
			["--preview"] = {
				type = "cmd",
				fn = function(items)
					local number = string.match(unpack(items), "%d+")
					return table.concat({
						-- First command.
						gh.cmd_view_pr(number),
						";",
						-- Second command.
						gh.cmd_view_pr_comments(number),
					}, " ")
				end,
			},
			["--preview-window"] = "wrap",
		},
		actions = {
			["default"] = function(selected)
				if selected ~= nil then
					vim.fn.setreg("", unpack(selected))
					print(selected)
				end
			end,
		},
	})
end

function M.fzf_gh_issues()
	local gh = require("github")
	local repo = gh.get_repo()

	return require("fzf-lua").fzf_live(function(q)
		return gh.cmd_search_issues(repo, q)
	end, {
		prompt = "Issues> ",
		fzf_opts = {
			["--preview"] = {
				type = "cmd",
				fn = function(items)
					local number = string.match(unpack(items), "%d+")
					return gh.cmd_view_issue(number)
				end,
			},
			["--preview-window"] = "wrap",
		},
		actions = {
			["default"] = function(selected)
				if selected ~= nil then
					vim.fn.setreg("", unpack(selected))
					print(selected)
				end
			end,
		},
	})
end

function M.setup()
	vim.api.nvim_create_user_command("FzfGitLog", M.fzf_git_log, { desc = "FZF git log" })
	vim.api.nvim_create_user_command("FzfGitReflog", M.fzf_git_reflog, { desc = "FZF git reflog" })
	vim.api.nvim_create_user_command("FzfPullRequests", M.fzf_gh_prs, { desc = "FZF pull requests" })
	vim.api.nvim_create_user_command("FzfIssues", M.fzf_gh_issues, { desc = "FZF issues" })
end

return M
