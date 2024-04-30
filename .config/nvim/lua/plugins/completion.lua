return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-nvim-lua",
			{
				"hrsh7th/vim-vsnip",
				init = function()
					vim.g.vsnip_snippet_dir = vim.fn.resolve(vim.fn.stdpath("config") .. "/snippets")
				end,
			},
			"hrsh7th/vim-vsnip-integ",
			"hrsh7th/cmp-vsnip",
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
					{ name = "nvim_lua", priority = 700 },
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
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.order,
						-- function(entry1, entry2)
						-- 	local preselect1 = entry1.completion_item.preselect or false
						-- 	local preselect2 = entry2.completion_item.preselect or false
						--
						-- 	if preselect1 ~= preselect2 then
						-- 		return preselect1
						-- 	end
						-- end,
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
				},
			})
		end,
	},
}
