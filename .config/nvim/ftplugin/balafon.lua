require("file_actions").registerFormatter({
	command = "balafon",
	args = { "fmt" },
})
require("file_actions").configureFormatBeforeSave({ "balafon" })

require("file_actions").registerLinter({
	exe = "balafon",
	args = { "lint" },
	errorformat = "%f:%l:%c: error: %m",
})
require("file_actions").configureLintAfterSave({ "balafon" })
