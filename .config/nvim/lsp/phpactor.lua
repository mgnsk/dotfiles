--- @type vim.lsp.Config
return {
	cmd = { "phpactor", "language-server" },
	filetypes = { "php", "phtml" },
	init_options = {
		["language_server_worse_reflection.inlay_hints.enable"] = true,
		["language_server_worse_reflection.inlay_hints.params"] = true,
		["language_server_worse_reflection.inlay_hints.types"] = true,
	},
}
