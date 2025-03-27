vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

require("file_actions").registerLinter({
	exe = "buf",
	args = { "lint" },
	errorformat = "%f:%l:%c:%m",
})
require("file_actions").configureLintAfterSave({ "buf" })
