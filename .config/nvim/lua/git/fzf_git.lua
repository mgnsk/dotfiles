local default_actions = {
	["default"] = function(selected)
		local line = unpack(selected)
		vim.fn.setreg("", line)
		vim.notify(line, vim.log.levels.INFO)
	end,
}

local M = {}

function M.fzf_git_log(opts)
	local log = require("git/git_log")

	return require("fzf-lua").fzf_live(log.cmd_search_log, {
		prompt = "Git log> ",
		preview = log.cmd_view_log(),
		actions = opts.actions or default_actions,
	})
end

function M.fzf_git_reflog(opts)
	local log = require("git/git_log")

	return require("fzf-lua").fzf_live(log.cmd_search_reflog, {
		prompt = "Git reflog> ",
		preview = log.cmd_view_log(),
		actions = opts.actions or default_actions,
	})
end

function M.fzf_gh_prs(opts)
	local gh = require("git/github")
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
		actions = opts.actions or default_actions,
	})
end

function M.fzf_gh_issues(opts)
	local gh = require("git/github")
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
		actions = opts.actions or default_actions,
	})
end

function M.setup()
	vim.api.nvim_create_user_command("FzfGitLog", M.fzf_git_log, { desc = "FZF git log" })
	vim.api.nvim_create_user_command("FzfRefLog", M.fzf_git_reflog, { desc = "FZF git reflog" })
	vim.api.nvim_create_user_command("FzfGithubPullRequests", M.fzf_gh_prs, { desc = "FZF github pull requests" })
	vim.api.nvim_create_user_command("FzfGithubIssues", M.fzf_gh_issues, { desc = "FZF github issues" })
end

return M
