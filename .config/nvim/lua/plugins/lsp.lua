-- location_callback opens all LSP gotos in a new tab
local location_callback = function(_, result, ctx)
	local util = vim.lsp.util

	if result == nil or vim.tbl_isempty(result) then
		require("vim.lsp.log").info(ctx["method"], "No location found")
		return nil
	end

	vim.api.nvim_command("tabnew")

	if vim.tbl_islist(result) then
		util.jump_to_location(result[1], "utf-8", false)
		if #result > 1 then
			vim.diagnostic.setqflist(util.locations_to_items(result, "utf-8"))
			vim.api.nvim_command("copen")
			vim.api.nvim_command("wincmd p")
		end
	else
		util.jump_to_location(result, "utf-8", false)
	end
end

return {
	{
		"simrat39/symbols-outline.nvim",
		lazy = true,
		init = function()
			local map = require("util").map

			map("n", "<leader>V", function()
				return require("symbols-outline").toggle_outline()
			end, { desc = "Toggle LSP symbols outline tree" })
		end,
		config = function()
			require("symbols-outline").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		cond = not os.getenv("NVIM_DIFF"),
		event = { "BufEnter" },
		dependencies = {
			{
				"ray-x/lsp_signature.nvim",
				config = function()
					-- require("lsp_signature").setup({})
				end,
			},
			{
				"folke/neodev.nvim",
				config = function()
					require("neodev").setup({})
				end,
			},
		},
		init = function()
			vim.lsp.handlers["textDocument/declaration"] = location_callback
			vim.lsp.handlers["textDocument/definition"] = location_callback
			vim.lsp.handlers["textDocument/typeDefinition"] = location_callback
			vim.lsp.handlers["textDocument/implementation"] = location_callback
			vim.lsp.handlers["textDocument/publishDiagnostics"] =
				vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
					update_in_insert = false,
				})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client ~= nil and client.server_capabilities.inlayHintProvider then
						vim.lsp.inlay_hint.enable(args.buf, true)
					end
					-- whatever other lsp config you want
				end,
			})

			local map = require("util").map

			map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
			map("n", "L", vim.diagnostic.open_float, { desc = "Hover diagnostic" })
			map("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
			map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto declaration" })
			map("n", "gi", vim.lsp.buf.implementation, { desc = "List implementations" })
			map("n", "go", vim.lsp.buf.type_definition, { desc = "Goto definition" })
			map("n", "gr", vim.lsp.buf.references, { desc = "List references" })
			map("n", "gs", vim.lsp.buf.signature_help, { desc = "Hover signature" })
			map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
			map("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })

			map("n", "gj", function()
				if vim.diagnostic.get_next() then
					vim.diagnostic.goto_next()
					return
				end

				local row, col = unpack(vim.api.nvim_win_get_cursor(0))
				local bufnr = vim.api.nvim_get_current_buf()
				local loclist = vim.fn.getloclist(0)
				require("util").sort_loclist(loclist)

				for _, entry in pairs(loclist) do
					if entry.bufnr == bufnr then
						if entry.lnum == row and entry.col > col or entry.lnum > row then
							vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
							return
						end
					end
				end

				vim.api.nvim_echo(
					{ { "No more valid diagnostics or location list items to move to", "WarningMsg" } },
					true,
					{}
				)
			end, { desc = "Goto next diagnostic or location list item in current buffer" })

			map("n", "gk", function()
				if vim.diagnostic.get_prev() then
					vim.diagnostic.goto_prev()
					return
				end

				local row, col = unpack(vim.api.nvim_win_get_cursor(0))
				local bufnr = vim.api.nvim_get_current_buf()
				local loclist = vim.fn.getloclist(0)
				require("util").sort_loclist(loclist)
				require("util").reverse(loclist)

				for _, entry in pairs(loclist) do
					if entry.bufnr == bufnr then
						if entry.lnum == row and entry.col < col or entry.lnum < row then
							vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
							return
						end
					end
				end

				vim.api.nvim_echo(
					{ { "No more valid diagnostics or location list items to move to", "WarningMsg" } },
					true,
					{}
				)
			end, { desc = "Goto prev diagnostic or location list item in current buffer" })
		end,
		config = function()
			local lsp = require("lspconfig")

			lsp.util.default_config = vim.tbl_deep_extend("force", lsp.util.default_config, {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
				on_init = function(client, bufnr)
					client.server_capabilities.semanticTokensProvider = nil
				end,
			})

			lsp.gopls.setup({})
			lsp.tsserver.setup({})
			lsp.html.setup({})
			lsp.cssls.setup({})
			lsp.bashls.setup({})
			lsp.lua_ls.setup({
				settings = {
					Lua = {
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						completion = {
							enable = true,
						},
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						telemetry = { enable = false },
					},
				},
			})
			lsp.phpactor.setup({})
			lsp.svelte.setup({})
			lsp.rust_analyzer.setup({})
		end,
	},
}
