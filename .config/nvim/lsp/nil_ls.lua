--- @type vim.lsp.Config
return {
	cmd = { "nil" },
	filetypes = { "nix" },
	root_markers = { "flake.nix" },
	settings = {
		["nil"] = {
			formatting = { command = { "nixfmt" } },
		},
	},
}
