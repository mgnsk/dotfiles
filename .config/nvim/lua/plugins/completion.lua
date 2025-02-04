--- @type LazySpec[]
return {
	{
		"saghen/blink.cmp",
		cond = not os.getenv("NVIM_DIFF"),
		event = "VeryLazy",
		-- use a release tag to download pre-built binaries
		version = "v0.11.0",
		config = function()
			vim.treesitter.language.register("blink-cmp-documentation", "")

			require("blink-cmp").setup({
				keymap = {
					preset = "none",
					["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
					["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
					["<CR>"] = { "accept", "fallback" },
					["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				},
				signature = { enabled = true },
				completion = {
					menu = {
						auto_show = function(ctx)
							return ctx.mode ~= "cmdline"
						end,
					},
					documentation = {
						auto_show = true,
						-- auto_show_delay_ms = 500,
					},
				},
				appearance = {
					nerd_font_variant = "mono",
				},
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
				},
			})
		end,
	},
}
