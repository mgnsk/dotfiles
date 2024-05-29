return {
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters = {
					balafon = {
						command = "balafon",
						args = { "fmt" },
					},
				},
				formatters_by_ft = {
					balafon = { "balafon" },
					css = { "prettier" },
					fish = { "fish_indent" },
					less = { "prettier" },
					markdown = { "prettier" },
					html = { "prettier" },
					json = { "prettier" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					typescriptreact = { "prettier" },
					twig = { "prettier" },
					lua = { "stylua" },
					glsl = { "clang-format" },
					proto = { "buf" },
					go = { "goimports" },
					rust = { "rustfmt" },
					sh = { "shfmt" },
					php = { "pint" },
				},
				format_on_save = {
					timeout_ms = 3000,
					lsp_fallback = false,
				},
			})
		end,
	},
}
