require("file_actions").registerFormatter({
	command = "caddy",
	args = { "fmt", "-" },
	stdin = true,
})
require("file_actions").configureFormatBeforeSave({ "caddy" })

vim.bo.commentstring = "# %s"
