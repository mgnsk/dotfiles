--- @type LazySpec[]
return {
	{
		"hrsh7th/nvim-cmp",
		dir = vim.fn.expand("$HOME/nvim-plugins/nvim-cmp"),
		dependencies = {
			{
				"hrsh7th/cmp-buffer",
				dir = vim.fn.expand("$HOME/nvim-plugins/cmp-buffer"),
			},
			{
				"hrsh7th/cmp-nvim-lsp",
				dir = vim.fn.expand("$HOME/nvim-plugins/cmp-nvim-lsp"),
			},
			{
				"hrsh7th/cmp-nvim-lsp-signature-help",
				dir = vim.fn.expand("$HOME/nvim-plugins/cmp-nvim-lsp-signature-help"),
			},
			{
				"hrsh7th/vim-vsnip",
				dir = vim.fn.expand("$HOME/nvim-plugins/vim-vsnip"),
				config = function()
					vim.g.vsnip_snippet_dir = vim.fn.resolve(vim.fn.stdpath("config") .. "/snippets")
				end,
			},
			{
				"hrsh7th/cmp-vsnip",
				dir = vim.fn.expand("$HOME/nvim-plugins/cmp-vsnip"),
			},
		},
		cond = not os.getenv("NVIM_DIFF"),
		event = { "InsertEnter" },
		config = function()
			local has_words_before = function()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local feedkey = function(key, mode)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
			end

			local cmp = require("cmp")

			cmp.setup({
				performance = {
					debounce = 0, -- default is 60ms
					throttle = 0, -- default is 30ms
				},
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				-- https://github.com/hrsh7th/nvim-cmp/issues/1621
				completion = {
					completeopt = "menu,menuone,noinsert", -- remove default noselect
				},
				preselect = cmp.PreselectMode.None,
				sources = cmp.config.sources({
					{ name = "vsnip", priority = 1000 },
					{ name = "nvim_lsp", priority = 900 },
					{ name = "nvim_lsp_signature_help", priority = 800 },
				}, {
					{
						name = "buffer",
						priority = 600,
						option = {
							get_bufnrs = function()
								return vim.api.nvim_list_bufs()
							end,
						},
					},
				}),
				matching = {
					disallow_fuzzy_matching = false,
					disallow_fullfuzzy_matching = false,
					disallow_partial_fuzzy_matching = false,
					disallow_partial_matching = false,
					disallow_prefix_unmatching = false,
					disallow_symbol_nonprefix_matching = false,
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.config.compare.locality,
						cmp.config.compare.order,
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						-- compare.scopes,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						-- cmp.config.compare.length,
						cmp.config.compare.kind,
						-- compare.sort_text,
					},
				},
				mapping = {
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.fn["vsnip#available"](1) == 1 then
							feedkey("<Plug>(vsnip-expand-or-jump)", "")
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.fn["vsnip#jumpable"](-1) == 1 then
							feedkey("<Plug>(vsnip-jump-prev)", "")
						end
					end, { "i", "s" }),

					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Insert,
						select = false,
					}),

					["<C-Space>"] = cmp.mapping.complete(),
				},
			})
		end,
	},
}
