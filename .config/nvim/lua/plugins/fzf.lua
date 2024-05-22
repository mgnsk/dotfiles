local map = require("util").map

return {
	{
		"ibhagwan/fzf-lua",
		lazy = true,
		init = function()
			map("n", "<leader>p", function()
				return require("fzf-lua").builtin()
			end, { desc = "FZF builtin" })

			map("n", "<leader>/", function()
				return require("fzf-lua").commands()
			end, { desc = "FZF commands" })

			map("n", "<leader>b", function()
				return require("fzf-lua").buffers()
			end, { desc = "FZF buffers" })

			-- Grep a single pattern.
			map("n", "<leader>g", function()
				return require("fzf-lua").live_grep()
			end, { desc = "FZF live_grep" })

			-- Grep all words separately, including filename.
			map("n", "<leader>a", function()
				return require("fzf-lua").grep_project({ fzf_opts = { ["--nth"] = false } })
			end, { desc = "FZF grep_project" })

			map("n", "<leader>o", function()
				return require("fzf-lua").files()
			end, { desc = "FZF files" })

			map("n", "<leader>f", function()
				return require("fzf-lua").lsp_live_workspace_symbols()
			end, { desc = "FZF lsp_live_workspace_symbols" })

			map("n", "<leader>h", function()
				return require("fzf-lua").git_bcommits()
			end, { desc = "FZF git_bcommits" })

			map("n", "<leader>H", function()
				return require("fzf-lua").git_commits()
			end, { desc = "FZF commits" })
		end,
		config = function()
			require("fzf-lua").setup({
				winopts = {
					fullscreen = true,
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
}
