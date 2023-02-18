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

require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        priority = 1000,
        config = function()
            require("nvim-treesitter.configs").setup({
                highlight = { enable = true },
                auto_install = true,
                --incremental_selection = {enable = true},
                -- textobjects = { enable = true },
            })
        end,
    },
    {
        "RRethy/vim-illuminate",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("illuminate").configure({
                providers = {
                    "treesitter",
                },
                delay = vim.o.updatetime,
            })
        end,
    },
    {
        "rktjmp/lush.nvim",
        priority = 1000,
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
                php = { "php-cs-fixer", "fix" },
            })
        end,
    },
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
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
    "airblade/vim-gitgutter",
    "tpope/vim-fugitive",
    {
        "neomake/neomake",
        enabled = not os.getenv("NVIM_DIFF"),
        config = function()
            vim.g.neomake_open_list = 2
            vim.g.neomake_typescript_enabled_makers = { "tsc", "eslint" }
            vim.g.neomake_go_enabled_makers = { "go", "golangci_lint", "golint" }
            vim.g.neomake_c_enabled_makers = { "gcc" }
            vim.g.neomake_php_enabled_makers = { "php", "phpstan" }
            vim.fn["neomake#configure#automake"]("w")
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
        lazy = true,
        config = function()
            require("symbols-outline").setup()
        end,
    },
    {
        "williamboman/mason.nvim",
        build = function()
            local servers = {
                "dockerfile-language-server",
                "gopls",
                "revive",
                "goimports",
                "golangci-lint",
                "buf",
                "typescript-language-server",
                "html-lsp",
                "css-lsp",
                "prettier",
                "bash-language-server",
                "lua-language-server",
                "intelephense",
                "php-cs-fixer",
                "phpstan",
                "ansible-language-server",
                "ansible-lint",
                "yamllint",
                "shellcheck",
                "shfmt",
                "luacheck",
                "hadolint",
                "stylua",
                "markdownlint",
            }
            vim.cmd(string.format("MasonInstall %s", table.concat(servers, " ")))
        end,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        enabled = not os.getenv("NVIM_DIFF"),
        dependencies = {
            "williamboman/mason.nvim",
            {
                "folke/neodev.nvim",
                config = function()
                    require("neodev").setup({})
                end,
            },
        },
        config = function()
            local lsp = require("lspconfig")
            lsp.dockerls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.gopls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.tsserver.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.html.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.cssls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.bashls.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.lua_ls.setup({
                capabilities = capabilities,
                on_attach = on_attach,
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
            lsp.intelephense.setup({ capabilities = capabilities, on_attach = on_attach })
            lsp.ansiblels.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                -- TODO: neomake ansiblelint broken, linting with ansiblels
                -- settings = {
                --     ansible = {
                --         validation = {
                --             lint = {
                --                 enabled = false,
                --             },
                --         },
                --     },
                -- },
            })

            vim.lsp.handlers["textDocument/declaration"] = location_callback
            vim.lsp.handlers["textDocument/definition"] = location_callback
            vim.lsp.handlers["textDocument/typeDefinition"] = location_callback
            vim.lsp.handlers["textDocument/implementation"] = location_callback
            vim.lsp.handlers["textDocument/publishDiagnostics"] =
                vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
                    update_in_insert = false,
                })

            -- vim.cmd([[ hi def link LspReferenceText CursorLine ]])
            -- vim.cmd([[ hi def link LspReferenceWrite CursorLine ]])
            -- vim.cmd([[ hi def link LspReferenceRead CursorLine ]])
        end,
    },
    {
        "simrat39/rust-tools.nvim",
        ft = "rust",
        enabled = not os.getenv("NVIM_DIFF"),
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
        enabled = not os.getenv("NVIM_DIFF"),
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
    "pearofducks/ansible-vim",
})
