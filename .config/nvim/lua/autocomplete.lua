local cmp = require "cmp"
cmp.setup(
    {
        sources = {
            {name = "nvim_lsp"},
            {name = "buffer"},
            {name = "nvim_lua"},
            {name = "path"}
        },
        sorting = {
            comparators = {
                cmp.config.compare.score,
                cmp.config.compare.offset
            }
        },
        mapping = {
            ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), {"i", "s"}),
            ["<CR>"] = cmp.mapping.confirm(
                {
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = true
                }
            )
        }
    }
)
