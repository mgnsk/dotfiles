--- @type vim.lsp.Config
return {
	settings = {
		yaml = {
			schemas = {
				kubernetes = "*.yaml",
				["https://json.schemastore.org/github-workflow"] = ".github/workflows/*",
				["https://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
				["https://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
				["https://www.schemastore.org/dependabot-2.0.json"] = ".github/dependabot.{yml,yaml}",
				["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*compose*.{yml,yaml}",
				["https://moonrepo.dev/schemas/toolchain.json"] = ".moon/toolchain.yml",
				["https://moonrepo.dev/schemas/workspace.json"] = ".moon/workspace.yml",
				["https://moonrepo.dev/schemas/tasks.json"] = ".moon/tasks/**/*.yml",
				["https://moonrepo.dev/schemas/project.json"] = "**/moon.yml",
			},
		},
	},
}
