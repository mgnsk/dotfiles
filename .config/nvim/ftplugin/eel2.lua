vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

require("file_actions").registerLinter({
	exe = "jsfx-lint",
	cwd = "%:p:h", -- Run linter in the file's directory.
	errorformat = table.concat({
		[[%A%t%*[A-Za-z]: %m]],
		[[%C%*[\ ]--> %f:%l:%c (%m)]],
		[[%Z]],
	}, ","),
})
require("file_actions").configureLintAfterSave({ "jsfx-lint" })
