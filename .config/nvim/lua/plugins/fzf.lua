--- @type LazySpec[]
return {
	{
		"ibhagwan/fzf-lua",
		lazy = true,
		init = function()
			vim.keymap.set("n", "<leader>p", function()
				return require("fzf-lua").builtin()
			end, { desc = "FZF builtin" })

			vim.keymap.set("n", "<leader>/", function()
				return require("fzf-lua").commands()
			end, { desc = "FZF commands" })

			vim.keymap.set("n", "<leader>b", function()
				return require("fzf-lua").buffers()
			end, { desc = "FZF buffers" })

			-- Grep a single pattern.
			vim.keymap.set("n", "<leader>g", function()
				return require("fzf-lua").live_grep()
			end, { desc = "FZF live_grep" })

			-- Grep all words separately, including filename.
			vim.keymap.set("n", "<leader>a", function()
				return require("fzf-lua").grep_project({ fzf_opts = { ["--nth"] = false } })
			end, { desc = "FZF grep_project" })

			vim.keymap.set("n", "<leader>o", function()
				return require("fzf-lua").files()
			end, { desc = "FZF files" })

			vim.keymap.set("n", "<leader>f", function()
				return require("fzf-lua").lsp_live_workspace_symbols()
			end, { desc = "FZF lsp_live_workspace_symbols" })

			vim.keymap.set("n", "<leader>h", function()
				return require("fzf-lua").git_bcommits()
			end, { desc = "FZF git_bcommits" })

			vim.keymap.set("n", "<leader>H", function()
				return require("fzf-lua").git_commits()
			end, { desc = "FZF commits" })

			vim.keymap.set("n", "<leader>B", function()
				local lineArg =
					string.format([[ -L %s,%s:%s]], vim.fn.line("."), vim.fn.line("."), vim.fn.expand("%:p"))
				local gitCmd = require("fzf-lua").defaults.git.commits.cmd
				local contentsCmd = gitCmd .. " --no-patch" .. lineArg .. " | nl -ba" -- Add line numbers.

				return require("fzf-lua").fzf_exec(contentsCmd, {
					prompt = "Blame> ",
					fzf_opts = { ["--with-nth"] = "2.." }, -- Without the added line numbers.
					preview = {
						type = "cmd",
						fn = function(items)
							-- Skip this many entries in preview to only show the current selected.
							local skip = tonumber(string.match(items[1], "%d")) - 1
							return gitCmd
								.. lineArg
								.. " --max-count=1"
								.. string.format(" --skip=%d", skip)
								.. " | delta"
						end,
					},
				})
			end, { desc = "FZF blame current line" })
		end,
		config = function()
			require("fzf-lua").setup({
				winopts = {
					fullscreen = true,
					preview = {
						delay = 0,
						wrap = "wrap",
					},
				},
				files = {
					fd_opts = os.getenv("FZF_DEFAULT_COMMAND"):gsub("fd ", ""),
				},
				grep = {
					rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512 --hidden --glob=!.git/",
				},
				defaults = {
					git_icons = false,
					file_icons = false,
				},
			})
		end,
	},
}
