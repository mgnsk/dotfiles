vim.g.neomake_balafon_balafon_maker = {
	exe = "balafon",
	args = "lint",
	errorformat = "%f:%l:%c: error: %m",
}

require("file_actions").configureFormatBeforeSave({ "balafon" })
require("file_actions").configureLintAfterSave({ "balafon" })
