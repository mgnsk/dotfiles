return {
	{
		"stevearc/conform.nvim",
		lazy = true,
		config = function()
			require("conform").setup({
				format_on_save = {
					timeout_ms = 5000,
					lsp_fallback = false,
				},
			})
		end,
	},
}
