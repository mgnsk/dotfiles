local GitLog = {}

---@param q string
---@return string
function GitLog.cmd_search_log(q)
	return table.concat({
		"git",
		"log",
		"--all",
		"--color",
		"--decorate",
		"--pretty=format:'%C(yellow)%h %Cred%cr %Cblue(%an)%C(cyan)%d%Creset %s'",
		"-G",
		string.format([["%s"]], q),
	}, " ")
end

---@param q string
---@return string
function GitLog.cmd_search_reflog(q)
	return table.concat({
		"git",
		"reflog",
		"--all",
		"--color",
		"--decorate",
		"--pretty=format:'%C(yellow)%h %Cred%cr %Cblue(%an)%C(cyan)%d%Creset %s'",
		"-G",
		string.format([["%s"]], q),
	}, " ")
end

-- Show the diffs whose patch text contains the query. Pipe through rg to highlight the query.
---@return string
function GitLog.cmd_view_log()
	return "git show --color -G {q} {1} | rg  --colors=match:fg:blue --color=always --passthru {q}"
end

return GitLog
