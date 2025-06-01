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

			vim.keymap.set("v", "<leader>B", function()
				---@return {start_line: number, end_line: number}
				local selection = function()
					local cursor_line = vim.fn.line(".")
					local end_line = vim.fn.line("v")

					if cursor_line < end_line then
						return { cursor_line, end_line }
					else
						return { end_line, cursor_line }
					end
				end

				local start_line, end_line = unpack(selection())
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
								.. " | diff-highlight"
						end,
					},
				})
			end, { desc = "FZF blame selected lines" })
		end,
		config = function()
			local function git_show_in_new_buf(commit)
				local output = vim.fn.systemlist("git show " .. commit)
				vim.cmd("tabnew")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
				vim.bo.buftype = "nofile"
				vim.bo.bufhidden = "wipe"
				vim.bo.modifiable = false
				vim.bo.filetype = "git"
			end

			local git_log_actions = {
				["ctrl-l"] = {
					fn = function(selected)
						vim.fn.system(string.format("gh browse %s", selected[1]))
					end,
					field_index = "{1}",
					exec_silent = true,
				},
				["ctrl-o"] = {
					fn = function(selected)
						vim.schedule(function()
							git_show_in_new_buf(selected[1])
						end)
					end,
					field_index = "{1}",
					exec_silent = true,
				},
			}

			require("fzf-lua").setup({
				winopts = {
					fullscreen = true,
					border = "none",
					preview = {
						border = "none",
						delay = 0,
						wrap = "wrap",
						scrollbar = "none",
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
				git = {
					bcommits = {
						cmd = [[git log --color --decorate --pretty=format:'%C(yellow)%h %Cred%cr %Cblue(%an)%C(cyan)%d%Creset %s' {file}]],
						preview_pager = "diff-highlight",
						actions = git_log_actions,
					},
					commits = {
						cmd = [[git log --color --decorate --pretty=format:'%C(yellow)%h %Cred%cr %Cblue(%an)%C(cyan)%d%Creset %s']],
						preview_pager = "diff-highlight",
						actions = git_log_actions,
					},
				},
				lsp = {
					async_or_timeout = true,
				},
				keymap = {
					fzf = {
						["ctrl-d"] = "preview-page-down",
						["ctrl-u"] = "preview-page-up",
					},
				},
			})
		end,
	},
}
