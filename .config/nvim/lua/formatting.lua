if os.getenv("NVIM_DIFF") then
	return
end

require("conform").setup({
	format_on_save = function(bufnr)
		-- Disable with a global or buffer-local variable
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		---@type conform.FormatOpts
		return { timeout_ms = 600000 }
	end,
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = "Disable autoformat-on-save",
	bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = "Re-enable autoformat-on-save",
})

require("file_actions").registerFormatter("balafon", {
	command = "balafon",
	args = { "fmt" },
})

require("file_actions").registerFormatter("caddy", {
	command = "caddy",
	args = { "fmt", "-" },
	stdin = true,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\n\+\%$//e]],
})
