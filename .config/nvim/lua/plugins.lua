local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

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

require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufEnter" },
        build = function()
            local parsers = {
                "bash",
                "beancount",
                "c",
                "comment",
                "cpp",
                "css",
                "dockerfile",
                "glsl",
                "go",
                "gomod",
                "gosum",
                "gowork",
                "html",
                "javascript",
                "lua",
                "php",
                "proto",
                "python",
                "query",
                "rust",
                "sql",
                "tlaplus",
                "toml",
                "twig",
                "typescript",
                "yaml",
            }

            for _, parser in ipairs(parsers) do
                local ok, result = pcall(vim.cmd, string.format("TSUpdateSync %s", parser))
                if not ok then
                    print(result)
                    os.exit(1)
                end
            end
        end,
        config = function()
            require("nvim-treesitter.configs").setup({
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        local max_filesize = 500 * 1024
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<cr>",
                        node_incremental = "<tab>",
                        scope_incremental = "<cr>",
                        node_decremental = "<s-tab>",
                    },
                },
                -- auto_install = true,
                -- textobjects = { enable = true },
            })
        end,
    },
    {
        "nvim-treesitter/playground",
        event = { "BufEnter" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
    },
    {
        "RRethy/vim-illuminate",
        event = { "BufEnter" },
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
        "Mofiqul/vscode.nvim",
        cond = #(vim.api.nvim_list_uis()) > 0,
        config = function()
            vim.o.background = "dark"

            local vscode = require("vscode")
            local c = require("vscode.colors").get_colors()
            local bg = "#101010"

            vscode.setup({
                transparent = true,
                -- Enable italic comment
                italic_comments = true,

                color_overrides = {
                    vscBack = bg,
                },

                group_overrides = {
                    CSpellBad = { link = "SpellBad" },
                    TabLine = { fg = c.vscGray, bg = bg },
                    TabLineFill = { fg = c.vscGray, bg = bg },
                    TabLineSel = { fg = c.vscFront, bg = bg },
                    Type = { fg = c.vscBlueGreen, bg = "NONE" },
                    TypeDef = { fg = c.vscBlueGreen, bg = "NONE" },
                    QuickfixLine = { fg = "NONE", bg = c.vscTabCurrent },
                    ["@namespace"] = { fg = c.vscLightBlue, bg = "NONE" },
                    ["@keyword.function"] = { fg = c.vscPink, bg = "NONE" },
                    ["@keyword.operator"] = { fg = c.vscPink, bg = "NONE" },
                    ["@function.macro"] = { fg = c.vscPink, bg = "NONE" },
                    ["@type.builtin"] = { fg = c.vscBlueGreen, bg = "NONE" },
                    ["@constant.builtin"] = { fg = c.vscYellowOrange, bg = "NONE" },
                    ["@constant"] = { link = "@variable" },
                },
            })
            vscode.load()
        end,
    },
    {
        "norcalli/nvim-colorizer.lua",
        ft = { "lua", "html", "css", "less" },
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
                go = { "goimports", "-w" },
                rust = { "rustfmt" },
                sh = { "shfmt", "-w" },
                php = { "pint" },
            })
        end,
    },
    {
        "tpope/vim-commentary",
        event = "BufEnter",
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
                git = {
                    commits = {
                        preview_pager = "delta",
                    },
                    bcommits = {
                        preview_pager = "delta",
                    },
                },
            })
        end,
    },
    {
        "airblade/vim-gitgutter",
        event = "BufEnter",
    },
    {
        "tpope/vim-fugitive",
        event = "BufEnter",
    },
    {
        "neomake/neomake",
        cond = not os.getenv("NVIM_DIFF"),
        event = { "BufEnter" },
        init = function()
            vim.g.neomake_open_list = 2
            vim.g.neomake_typescript_enabled_makers = { "tsc", "eslint" }
            -- Note: golangci_lint is configured to run go_vet.
            vim.g.neomake_go_enabled_makers = { "go", "golangci_lint", "golint" }
            vim.g.neomake_c_enabled_makers = { "gcc" }
        end,
        config = function()
            vim.fn["neomake#configure#automake"]("w")
        end,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({})
        end,
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
        "L3MON4D3/LuaSnip",
        lazy = true,
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "hrsh7th/cmp-nvim-lua",
            "FelipeLema/cmp-async-path",
        },
        cond = not os.getenv("NVIM_DIFF"),
        event = { "BufEnter" },
        config = function()
            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0
                    and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            local cmp = require("cmp")
            local compare = cmp.config.compare

            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "nvim_lsp_signature_help" },
                    { name = "buffer" },
                    { name = "nvim_lua" },
                    { name = "async_path" },
                },
                sorting = {
                    comparators = {
                        compare.offset,
                        compare.exact,
                        compare.score,
                        compare.recently_used,
                        compare.locality,
                        compare.kind,
                        compare.sort_text,
                        compare.length,
                        compare.order,
                    },
                },
                mapping = {
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        local luasnip = require("luasnip")
                        if cmp.visible() then
                            cmp.select_next_item()
                        -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
                        -- they way you will only jump inside the snippet region
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        local luasnip = require("luasnip")
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
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
    {
        "neovim/nvim-lspconfig",
        cond = not os.getenv("NVIM_DIFF"),
        event = { "BufEnter" },
        dependencies = {
            "hrsh7th/nvim-cmp",
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
        end,
        config = function()
            local lsp = require("lspconfig")

            lsp.util.default_config = vim.tbl_deep_extend("force", lsp.util.default_config, {
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
                on_attach = function(client, bufnr)
                    client.server_capabilities.document_formatting = false
                    client.server_capabilities.semanticTokensProvider = nil
                    require("lsp_signature").on_attach({}, bufnr)
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
            lsp.ansiblels.setup({})
        end,
    },
    {
        "simrat39/rust-tools.nvim",
        ft = "rust",
        cond = not os.getenv("NVIM_DIFF"),
        dependencies = {
            "neovim/nvim-lspconfig",
        },
        config = function()
            local rt = require("rust-tools")
            rt.setup({})
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
        "mgnsk/table_gen.lua",
        lazy = true,
    },
    "pearofducks/ansible-vim",
    "chaoren/vim-wordmotion",
    {
        "ojroques/nvim-osc52",
        config = function()
            local function copy(lines, _)
                require("osc52").copy(table.concat(lines, "\n"))
            end

            local function paste()
                return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
            end

            vim.g.clipboard = {
                name = "osc52",
                copy = { ["+"] = copy, ["*"] = copy },
                paste = { ["+"] = paste, ["*"] = paste },
            }
        end,
    },
    {
        "ryuichiroh/vim-cspell",
        cmd = "CSpell",
        init = function()
            vim.g.cspell_disable_autogroup = true
        end,
    },
    {
        "mbbill/undotree",
        event = "BufEnter",
    },
})
