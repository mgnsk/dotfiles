--- @type LazySpec[]
return {
	{
		"romus204/tree-sitter-manager.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/tree-sitter-manager.nvim"),
		event = "VeryLazy",
		config = function()
			require("tree-sitter-manager").setup({
				ensure_installed = {
					"bash",
					"beancount",
					"caddy",
					"css",
					"dockerfile",
					"go",
					"python",
				},
			})
		end,
	},
}
