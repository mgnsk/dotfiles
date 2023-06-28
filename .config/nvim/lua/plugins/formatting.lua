return {
	{
		"mgnsk/sync-format.nvim",
		event = "BufEnter",
		config = function()
			require("formatter").setup({
				css = { "prettier", "-w" },
				less = { "prettier", "-w" },
				markdown = { "prettier", "-w" },
				html = { "prettier", "-w" },
				json = { "prettier", "-w" },
				javascript = { "prettier", "-w" },
				typescript = { "prettier", "-w" },
				lua = { "stylua" },
				c = { "clang-format", "-i" },
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
