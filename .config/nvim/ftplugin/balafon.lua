require("file_actions").registerFormatter("balafon", {
	command = "balafon",
	args = { "fmt" },
})

require("file_actions").configureFormatBeforeSave({ "balafon" })

require("lint").linters.balafon = {
	name = "balafon",
	cmd = "balafon",
	stdin = false,
	append_fname = true,
	args = { "lint" },
	stream = "stderr",
	ignore_exitcode = true,
	parser = require("lint.parser").from_errorformat("%f:%l:%c: error: %m", {}),
}

require("file_actions").configureLintAfterSave({ "balafon" })
