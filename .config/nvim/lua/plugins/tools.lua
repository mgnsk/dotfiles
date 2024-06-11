return {
	{
		"neomake/neomake",
		cond = not os.getenv("NVIM_DIFF"),
		cmd = { "Neomake" },
		init = function()
			vim.g.neomake_open_list = 2
			vim.g.neomake_list_height = 5
			vim.g.neomake_typescript_enabled_makers = { "tsc", "eslint" }
			vim.g.neomake_go_enabled_makers = { "go", "govet", "golint" }
			vim.g.neomake_c_enabled_makers = { "gcc" }

			vim.g.neomake_balafon_lint_maker = {
				exe = "balafon",
				args = "lint",
				errorformat = "%f:%l:%c: error: %m",
			}

			vim.g.neomake_balafon_enabled_makers = { "lint" }

			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function()
					vim.cmd("Neomake")
				end,
			})
		end,
	},
	{
		"ryuichiroh/vim-cspell",
		cmd = "CSpell",
		init = function()
			vim.g.cspell_disable_autogroup = true
		end,
		config = function()
			vim.api.nvim_create_user_command("CSpell", function()
				vim.api.nvim_call_function("cspell#lint", {})
			end, { desc = "Run cspell on current buffer" })
		end,
	},
}
