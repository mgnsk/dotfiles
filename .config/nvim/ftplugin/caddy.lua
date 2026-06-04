require("file_actions").registerFormatter("caddy", {
	command = "caddy",
	args = { "fmt", "-" },
	stdin = true,
})

require("file_actions").configureFormatBeforeSave({ "caddy" })

vim.bo.commentstring = "# %s"
