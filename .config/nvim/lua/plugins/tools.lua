--- @type LazySpec[]
return {
	{
		"neomake/neomake",
		dir = vim.fn.expand("$HOME/.nvim-plugins/neomake"),
		cond = not os.getenv("NVIM_DIFF"),
		event = "VeryLazy",
		config = function()
			vim.g.neomake_open_list = 2
			vim.g.neomake_list_height = 3
		end,
	},
	{
		"ryuichiroh/vim-cspell",
		dir = vim.fn.expand("$HOME/.nvim-plugins/vim-cspell"),
		event = "VeryLazy",
		init = function()
			vim.g.cspell_disable_autogroup = true

			vim.api.nvim_create_user_command("CSpell", function()
				vim.api.nvim_call_function("cspell#lint", {})
			end, { desc = "Run cspell on current buffer" })
		end,
	},
	{
		"phelipetls/jsonpath.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/jsonpath.nvim"),
		ft = { "json" },
		config = function()
			vim.api.nvim_create_user_command("JSONPath", function()
				print(require("jsonpath").get(nil, 0))
			end, { desc = "Print current JSON path" })
		end,
	},
	{
		"stevearc/oil.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/oil.nvim"),
		cmd = "Oil",
		init = function()
			-- Confirm file operations with <CR>.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "oil_preview",
				callback = function(params)
					vim.keymap.set("n", "<CR>", "y", { buffer = params.buf, remap = true, nowait = true })
				end,
			})
		end,
		---@type oil.setupOpts
		opts = {
			use_default_keymaps = false,
			keymaps = {
				["<CR>"] = "actions.select",
				["<C-v>"] = {
					"actions.select",
					opts = { vertical = true },
					desc = "Open the entry in a vertical split",
				},
				["<C-s>"] = {
					"actions.select",
					opts = { horizontal = true },
					desc = "Open the entry in a horizontal split",
				},
				["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
				["<C-p>"] = "actions.preview",
				["-"] = "actions.parent",
			},
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
				-- Note: these settings correspond to the order of `ls -Alhv --group-directories-first`.
				natural_order = false,
				sort = {
					{ "type", "asc" },
					{ "name", "asc" },
				},
			},
			-- Don't disable netrw.
			default_file_explorer = false,
		},
	},
	{
		"nvim-lua/plenary.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/plenary.nvim"),
		lazy = true,
	},
	{
		"olimorris/codecompanion.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/codecompanion.nvim"),
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {
			strategies = {
				chat = {
					adapter = "gemini",
				},
				inline = {
					adapter = "gemini",
				},
				cmd = {
					adapter = "gemini",
				},
			},
			adapters = {
				http = {
					gemini = function()
						return require("codecompanion.adapters").extend("gemini", {
							env = {
								api_key = "cmd:secret-tool lookup apikey gemini",
							},
						})
					end,
				},
			},
		},
	},
}
