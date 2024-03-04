local M = {}

function M.make()
	local lines = { "" }

	if not vim.bo.makeprg then
		return
	end

	local old_cwd = vim.fn.getcwd()
	local rel_cwd = vim.fn.expand("%:p:h")

	local cmd = vim.fn.expandcmd(vim.bo.makeprg)
	-- local cmd = string.format("cd %s; %s", rel_cwd, vim.fn.expandcmd(vim.bo.makeprg))

	print(vim.inspect(cmd))

	local function on_event(job_id, data, event)
		if event == "stdout" or event == "stderr" then
			if data then
				vim.list_extend(lines, data)
			end
		end

		if event == "exit" then
			-- vim.api.nvim_set_current_dir(rel_cwd)
			vim.fn.setqflist({}, " ", {
				title = cmd,
				lines = lines,
				efm = vim.bo.errorformat,
			})
			vim.api.nvim_command("doautocmd QuickFixCmdPost")
			vim.cmd.copen()
			-- vim.api.nvim_set_current_dir(old_cwd)
		end
	end

	local job_id = vim.fn.jobstart(cmd, {
		cwd = rel_cwd,
		on_stderr = on_event,
		on_stdout = on_event,
		on_exit = on_event,
		stdout_buffered = true,
		stderr_buffered = true,
	})
end

return M
