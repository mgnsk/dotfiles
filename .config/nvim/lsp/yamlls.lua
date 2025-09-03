--- @type vim.lsp.Config
return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
	root_markers = { ".git" },
	settings = {
		redhat = { telemetry = { enabled = false } },
		yaml = {
			format = { enable = true },
			schemas = {
				kubernetes = "*.yaml",
				["https://json.schemastore.org/github-workflow"] = ".github/workflows/*",
				["https://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
				["https://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
				["https://www.schemastore.org/dependabot-2.0.json"] = ".github/dependabot.{yml,yaml}",
				["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*compose*.{yml,yaml}",
			},
		},
	},
	on_init = function(client)
		--- https://github.com/neovim/nvim-lspconfig/pull/4016
		--- Since formatting is disabled by default if you check `client:supports_method('textDocument/formatting')`
		--- during `LspAttach` it will return `false`. This hack sets the capability to `true` to facilitate
		--- autocmd's which check this capability
		client.server_capabilities.documentFormattingProvider = true
	end,
}
