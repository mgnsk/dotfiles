--- @type LazySpec[]
return {
	{
		"saghen/blink.cmp",
		dir = vim.fn.expand("$HOME/nvim-plugins/blink.cmp"),
		cond = not os.getenv("NVIM_DIFF"),
		event = "InsertEnter",
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "none",
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<C-x>"] = { "accept", "fallback" },
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			},
			signature = { enabled = true },
			completion = {
				trigger = {
					show_on_insert_on_trigger_character = false,
				},
				menu = {
					auto_show = function(ctx)
						return ctx.mode ~= "cmdline"
					end,
				},
				documentation = {
					auto_show = true,
				},
			},
			fuzzy = {
				implementation = "lua",
				sorts = {
					function(a, b)
						local source_priority = {
							buffer = 4,
							lsp = 3,
							path = 2,
							snippets = 1,
						}

						local a_priority = source_priority[a.source_id]
						local b_priority = source_priority[b.source_id]
						if a_priority ~= b_priority then
							return a_priority > b_priority
						end
					end,
					-- defaults
					"exact",
					"score",
					"sort_text",
				},
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			sources = {
				default = function(ctx)
					local success, node = pcall(vim.treesitter.get_node)
					if
						success
						and node
						and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type())
					then
						return { "buffer" }
					else
						return { "lsp", "path", "snippets", "buffer" }
					end
				end,
			},
		},
	},
}
