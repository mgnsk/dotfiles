vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

vim.g.neomake_proto_buf_maker = {
	exe = "buf",
	args = "lint",
	errorformat = "%f:%l:%c:%m",
}

require("file_actions").configureFormatBeforeSave({ "buf" })
require("file_actions").configureLintAfterSave({ "buf" })
