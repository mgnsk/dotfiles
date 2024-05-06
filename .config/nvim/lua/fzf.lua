local function create_git_search(cwd, log_source, prompt)
	return require("fzf-lua").fzf_live(function(q)
		local cmd = table.concat({
			"git",
			"-C",
			cwd,
			log_source,
			"--all",
			"--color",
			"--decorate",
			"--pretty=format:'%C(yellow)%h %Cred%cr %Cblue(%an)%C(cyan)%d'",
			"-G",
			string.format([["%s"]], q),
		}, " ")
		return cmd
	end, {
		prompt = prompt,
		-- Show the diffs whose patch text contains the query. Pipe through rg to highlight the query.
		preview = string.format(
			"git -C %s show --color -G {q} {1} | rg  --colors=match:fg:blue --color=always --passthru {q}",
			cwd
		),
		actions = {
			["default"] = function(selected)
				-- On select, yank the log line.
				vim.fn.setreg("", unpack(selected))
			end,
		},
	})
end

local M = {}

function M.fzf_git_log()
	return create_git_search(vim.fn.getcwd(), "log", "git log> ")
end

function M.fzf_git_reflog()
	return create_git_search(vim.fn.getcwd(), "reflog", "git reflog> ")
end

return M
