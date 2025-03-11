--- @type LazySpec[]
return {
	{
		"saghen/blink.cmp",
		dir = vim.fn.stdpath("data") .. "/plugins/blink.cmp",
		cond = not os.getenv("NVIM_DIFF"),
		event = "InsertEnter",
		build = "nix run .#build-plugin",
		config = function()
			require("blink-cmp").setup({
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
