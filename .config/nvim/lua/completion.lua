if os.getenv("NVIM_DIFF") then
	return
end

require("blink.cmp").setup({
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
		implementation = "rust",
		sorts = {
			"exact",
			"score",
			"sort_text",
			function(a, b)
				local source_priority = {
					buffer = 4,
					lsp = 3,
					snippets = 2,
					path = 1,
				}

				local a_priority = source_priority[a.source_id] or 0
				local b_priority = source_priority[b.source_id] or 0
				if a_priority ~= b_priority then
					return a_priority > b_priority
				end
			end,
		},
	},
	sources = {
		default = function()
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

			if
				(vim.bo.filetype == "sh" or vim.bo.filetype == "bash") and in_treesitter_capture({ "word", "string" })
			then
				return { "buffer", "path" }
			end

			if in_treesitter_capture({ "comment", "line_comment", "block_comment" }) then
				return { "buffer" }
			end

			return { "lsp", "snippets", "buffer" }
		end,
		providers = {
			buffer = {
				opts = {
					get_bufnrs = function()
						return vim.tbl_filter(function(bufnr)
							return vim.bo[bufnr].buftype == ""
						end, vim.api.nvim_list_bufs())
					end,
				},
			},
		},
	},
})
