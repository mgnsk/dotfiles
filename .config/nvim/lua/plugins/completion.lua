--- @type LazySpec[]
return {
	{
		"saghen/blink.cmp",
		dir = vim.fn.expand("$HOME/.nvim-plugins/blink.cmp"),
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
					draw = {
						columns = { { "label", "label_description", gap = 1 }, { "kind" } },
					},
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
			sources = {
				default = function(ctx)
					---@param args string[]
					local function in_treesitter_capture(args)
						local r, c = unpack(vim.api.nvim_win_get_cursor(0))
						r = r - 1 -- Convert to 0-indexed.
						if c > 0 then
							-- Use the previous column from cursor. Fixes the issue where
							-- treesitter doesn't detect the correct node.
							c = c - 1
						end

						local node = vim.treesitter.get_node({ pos = { r, c } })
						while node do
							if vim.tbl_contains(args, node:type()) then
								return true
							end
							node = node:parent()
						end
					end

					if vim.bo.filetype == "sh" and in_treesitter_capture({ "word", "string" }) then
						return { "buffer", "path" }
					end

					if in_treesitter_capture({ "comment", "line_comment", "block_comment" }) then
						return { "buffer" }
					end

					return { "lsp", "snippets", "buffer" }
				end,
			},
		},
	},
}
