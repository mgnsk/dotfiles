return {
	{
		"mgnsk/sync-format.nvim",
		event = "BufWritePost",
		config = function()
			require("formatter").setup({
				balafon = { "balafon", "fmt", "-w" },
				css = { "prettier", "-w" },
				fish = { "fish", "-c", [['fish_indent -w $argv[1]']] },
				less = { "prettier", "-w" },
				markdown = { "prettier", "-w" },
				html = { "prettier", "-w" },
				json = { "prettier", "-w" },
				javascript = { "prettier", "-w" },
				typescript = { "prettier", "-w" },
				typescriptreact = { "prettier", "-w" },
				twig = { "prettier", "-w" },
				lua = { "stylua" },
				c = { "clang-format", "-i" },
				cpp = { "clang-format", "-i" },
				glsl = { "clang-format", "-i" },
				proto = { "buf", "format", "-w" },
				go = { "goimports", "-w" },
				rust = { "rustfmt" },
				sh = { "shfmt", "-w" },
				php = { "pint" },
			})
		end,
	},
}
