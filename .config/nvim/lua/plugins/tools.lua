return {
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
        "ryuichiroh/vim-cspell",
        cmd = "CSpell",
        init = function()
            vim.g.cspell_disable_autogroup = true
        end,
    },
}
