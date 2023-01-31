local capabilities = vim.lsp.protocol.make_client_capabilities()

local function on_attach(client, bufnr)
    client.server_capabilities.document_formatting = false
    require("lsp_signature").on_attach({}, bufnr) -- Note: add in lsp client on-attach
end

-- location_callback opens all LSP gotos in a new tab
local location_callback = function(_, result, ctx)
    local util = vim.lsp.util

    if result == nil or vim.tbl_isempty(result) then
        require("vim.lsp.log").info(ctx["method"], "No location found")
        return nil
    end

    vim.api.nvim_command("tab split")

    if vim.tbl_islist(result) then
        util.jump_to_location(result[1], "utf-8")
        if #result > 1 then
            util.set_qflist(util.locations_to_items(result))
            vim.api.nvim_command("copen")
            vim.api.nvim_command("wincmd p")
        end
    else
        util.jump_to_location(result)
    end
end

require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-treesitter/playground",
        },
        lazy = false,
        priority = 1000,
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
                highlight = { enable = true },
                --incremental_selection = {enable = true},
                --textobjects = {enable = true}
            })
        end,
    },
    {
        "rktjmp/lush.nvim",
        lazy = false,
        priority = 1000,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            vim.cmd("colorscheme codedarker")
        end,
    },
    {
        "norcalli/nvim-colorizer.lua",
        ft = { "lua", "html", "css", "less", "markdown" },
        config = function()
            local opts = {
                RGB = true,
                RRGGBB = true,
                names = false,
                rgb_fn = true,
                hsl_fn = true,
                css = true,
            }
            require("colorizer").setup({
                "*",
                lua = opts,
                html = opts,
                css = opts,
                less = opts,
                markdown = opts,
            })
        end,
    },
    {
        "mgnsk/sync-format.nvim",
        config = function()
            require("formatter").setup({
                css = { "prettier", "-w" },
                less = { "prettier", "-w" },
                markdown = { "prettier", "-w" },
                html = { "prettier", "-w" },
                json = { "prettier", "-w" },
                javascript = { "prettier", "-w" },
                typescript = { "prettier", "-w" },
                lua = { "stylua", "--indent-type", "Spaces", "--indent-width", "4" },
                c = { "clang-format", "-i" },
                glsl = { "clang-format", "-i" },
                proto = { "buf", "format", "-w" },
                dockerfile = { "dockerfile_format" },
                go = { "goimports", "-w" },
                rust = { "rustfmt" },
                sh = { "shfmt", "-w" },
                sql = { "pg_format", "-i", "--type-case", "0" },
            })
        end,
    },
    {
        "b3nj5m1n/kommentary",
        config = function()
            require("kommentary.config").configure_language("default", {
                prefer_single_line_comments = true,
            })
        end,
    },
    {
        "ibhagwan/fzf-lua",
        lazy = true,
        config = function()
            require("fzf-lua").setup({
                winopts = {
                    preview = {
                        delay = 0,
                    },
                },
                grep = {
                    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512 --hidden --no-ignore-vcs --glob=!.git/",
                },
            })
        end,
    },
    {
        "AckslD/nvim-neoclip.lua",
        lazy = true,
        dependencies = {
            "ibhagwan/fzf-lua",
        },
        config = function()
            require("neoclip").setup()
        end,
    },
    "airblade/vim-gitgutter",
    "tpope/vim-fugitive",
    {
        "neomake/neomake",
        -- event = "BufWritePost",
        -- enabled = function()
        --     return not os.getenv("NVIM_DIFF")
        -- end,
        config = function()
            vim.g.neomake_open_list = 2
            vim.g.neomake_typescript_enabled_makers = { "tsc", "eslint" }
            vim.g.neomake_go_enabled_makers = { "go", "golangci_lint", "golint" }
            vim.g.neomake_c_enabled_makers = { "gcc" }
            vim.call("neomake#configure#automake", "w")
        end,
    },
    {
        "Townk/vim-autoclose", -- TODO: check out alternatives
        event = "InsertEnter",
    },
    {
        "ray-x/lsp_signature.nvim",
        lazy = true,
    },
    {
        "simrat39/symbols-outline.nvim",
        cmd = "SymbolsOutline",
        dependencies = {
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("symbols-outline").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        -- event = "BufWritePost",
        -- enabled = function()
        --     return not os.getenv("NVIM_DIFF")
        -- end,
        dependencies = {
            {
                "folke/neodev.nvim",
                ft = "lua",
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

            -- vim.api.nvim_command([[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]])
            -- vim.api.nvim_command([[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]])
            -- vim.api.nvim_command([[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]])

            vim.api.nvim_command([[ hi def link LspReferenceText CursorLine ]])
            vim.api.nvim_command([[ hi def link LspReferenceWrite CursorLine ]])
            vim.api.nvim_command([[ hi def link LspReferenceRead CursorLine ]])
        end,
        config = function()
            local lsp = require("lspconfig")
            lsp.dockerls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.gopls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.intelephense.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.tsserver.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.html.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.cssls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.bashls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.sumneko_lua.setup({
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
        end,
    },
    {
        "simrat39/rust-tools.nvim",
        ft = "rust",
        -- enabled = function()
        --     return not os.getenv("NVIM_DIFF")
        -- end,
        dependencies = {
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("rust-tools").setup({
                server = {
                    capabilities = capabilities,
                    on_attach = on_attach,
                },
            })
        end,
    },
    {
        "ellisonleao/glow.nvim",
        ft = "markdown",
        config = function()
            require("glow").setup({})
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "nvim_lua" },
                    { name = "path" },
                },
                sorting = {
                    comparators = {
                        cmp.config.compare.score,
                        cmp.config.compare.offset,
                    },
                },
                mapping = {
                    ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "s" }),
                    ["<CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                },
            })
        end,
    },
    {
        "mgnsk/table_gen.lua",
        lazy = true,
    },
})
