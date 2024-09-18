--- @type LazySpec[]
return {
	{
		"neomake/neomake",
		cond = not os.getenv("NVIM_DIFF"),
		event = "BufEnter",
		config = function()
			vim.g.neomake_open_list = 2
		end,
	},
	{
		"ryuichiroh/vim-cspell",
		cmd = "CSpell",
		init = function()
			vim.g.cspell_disable_autogroup = true

			vim.api.nvim_create_user_command("CSpell", function()
				vim.api.nvim_call_function("cspell#lint", {})
			end, { desc = "Run cspell on current buffer" })
		end,
	},
	{
		"phelipetls/jsonpath.nvim",
		lazy = true,
		init = function()
			vim.api.nvim_create_user_command("JSONPath", function()
				vim.fn.setreg("+", require("jsonpath").get())
			end, { desc = "Yank current JSON path to system clipboard" })
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
}
