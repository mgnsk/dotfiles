--- @type LazySpec[]
return {
	{
		"ibhagwan/fzf-lua",
		dir = vim.fn.stdpath("config") .. "/plugins/fzf-lua",
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
			end, { desc = "FZF grep inside files" })

			-- Grep all words separately, including filename.
			vim.keymap.set("n", "<leader>a", function()
				return require("fzf-lua").grep_project({ fzf_opts = { ["--nth"] = false } })
			end, { desc = "FZF powerful grep including file paths" })

			vim.keymap.set("n", "<leader>o", function()
				return require("fzf-lua").files()
			end, { desc = "FZF files" })

			vim.keymap.set("n", "<leader>O", function()
				return require("fzf-lua").oldfiles()
			end, { desc = "FZF recent files" })

			vim.keymap.set("n", "<leader>f", function()
				return require("fzf-lua").lsp_document_symbols()
			end, { desc = "FZF LSP document symbols" })

			vim.keymap.set("n", "<leader>F", function()
				return require("fzf-lua").lsp_live_workspace_symbols()
			end, { desc = "FZF LSP live workspace symbols" })

			vim.keymap.set("n", "<leader>h", function()
				return require("fzf-lua").git_bcommits()
			end, { desc = "FZF buffer commits" })

			vim.keymap.set("n", "<leader>H", function()
				return require("fzf-lua").git_commits()
			end, { desc = "FZF repo commits" })

			vim.keymap.set("n", "<leader>G", function()
				return require("fzf-lua").git_status()
			end, { desc = "FZF git status" })

			vim.keymap.set("v", "<leader>B", function()
				local start_line, end_line = unpack(require("util").selection())
				local lineArg = string.format([[ -L %d,%d:%s]], start_line, end_line, vim.fn.expand("%:p"))

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
			end, { desc = "FZF blame selected lines" })
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
				previewers = {
					builtin = {
						syntax = true,
						syntax_limit_b = require("const").treesitter_max_filesize,
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
				lsp = {
					async_or_timeout = true,
				},
			})
		end,
	},
}
