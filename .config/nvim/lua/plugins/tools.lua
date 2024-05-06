return {
	{
		"neomake/neomake",
		cond = not os.getenv("NVIM_DIFF"),
		event = { "BufEnter" },
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
		end,
		config = function()
			vim.fn["neomake#configure#automake"]("w")
		end,
	},
	{
		"ryuichiroh/vim-cspell",
		event = { "BufEnter" },
		init = function()
			vim.g.cspell_disable_autogroup = true
		end,
		config = function()
			vim.api.nvim_create_user_command("CSpell", function()
				vim.api.nvim_call_function("cspell#lint", {})
			end, { desc = "Run cspell on current buffer" })
		end,
	},
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
					fzf_opts = { ["--ansi"] = false },
				},
				grep = {
					rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512 --hidden --glob=!.git/",
				},
				git = {
					commits = {
						preview_pager = "delta",
					},
					bcommits = {
						preview_pager = "delta",
					},
				},
				defaults = {
					git_icons = false,
					file_icons = false,
				},
			})
		end,
	},
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		config = function()
			local oil = require("oil")

			oil.setup({
				view_options = {
					show_hidden = true,
					natural_order = false,
					sort = {
						{ "type", "asc" },
						{ "name", "asc" },
					},
				},
			})
		end,
		-- -- Optional dependencies
		-- dependencies = { "nvim-tree/nvim-web-devicons" },
	},
}
