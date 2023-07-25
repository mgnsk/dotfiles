return {
	{
		"ibhagwan/fzf-lua",
		lazy = true,
		config = function()
			require("fzf-lua").setup({
				winopts = {
					preview = {
						delay = 0,
					},
				},
				files = {
					fd_opts = os.getenv("FZF_DEFAULT_COMMAND"):gsub("fd ", ""),
				},
				grep = {
					rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512 --hidden --no-ignore-vcs --glob=!.git/",
				},
				git = {
					commits = {
						preview_pager = "delta",
					},
					bcommits = {
						preview_pager = "delta",
					},
				},
			})
		end,
	},
	{
		"neomake/neomake",
		cond = not os.getenv("NVIM_DIFF"),
		event = { "BufEnter" },
		init = function()
			vim.g.neomake_open_list = 2
			vim.g.neomake_typescript_enabled_makers = { "tsc", "eslint" }
			-- Note: golangci_lint is configured to run go_vet.
			vim.g.neomake_go_enabled_makers = { "go", "golangci_lint", "golint" }
			vim.g.neomake_c_enabled_makers = { "gcc" }

			vim.g.neomake_balafon_lint_maker = {
				exe = "balafon",
				args = "lint",
				errorformat = "%f:%l:%c: error: %m",
			}

			vim.g.neomake_balafon_enabled_makers = { "lint" }
		end,
		config = function()
			vim.fn["neomake#configure#automake"]("w")
		end,
	},
	{
		"simrat39/rust-tools.nvim",
		ft = "rust",
		cond = not os.getenv("NVIM_DIFF"),
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		config = function()
			local rt = require("rust-tools")
			rt.setup({})
		end,
	},
	{
		"ryuichiroh/vim-cspell",
		cmd = "CSpell",
		init = function()
			vim.g.cspell_disable_autogroup = true
		end,
	},
}
