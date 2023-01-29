local opts = { noremap = true, silent = true }

vim.g.mapleader = ","

vim.keymap.set("v", "Y", [["+y<CR>]], { desc = "Yank to system clipboard" })
vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape from insert mode" })
vim.keymap.set("t", "jj", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

vim.keymap.set("n", "qq", function()
    local buf_count = #(vim.fn.getbufinfo({ buflisted = 1 }))

    if vim.fn.expand("%") == "" and buf_count == 1 then
        vim.cmd("q!")
    else
        vim.cmd("bd!")
    end
end, { desc = "Kill buffer" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Goto to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Goto bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Goto upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Goto right window" })

vim.keymap.set("n", "<leader>.", ":", { desc = "Command mode" })
vim.keymap.set(
    "n",
    "<leader>,",
    ":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>",
    { desc = "Open new terminal window to right" }
)
vim.keymap.set(
    "n",
    "tt",
    ":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>",
    { desc = "Open new terminal tab" }
)
vim.keymap.set("n", "<leader>v", ":vnew<CR>", { desc = "Open new window to right" })
vim.keymap.set("n", "<leader>s", ":new<CR>", { desc = "Open new window to bottom" })
vim.keymap.set("n", "<leader>t", ":tabnew<CR>", { desc = "Open new tab" })
vim.keymap.set("n", "<leader>e", ":Tex<CR>", { desc = "Open file browser in new tab" })
vim.keymap.set("n", "<leader>j", ":bnext<CR>", { desc = "Switch to next buffer" })
vim.keymap.set("n", "<leader>k", ":bprev<CR>", { desc = "Switch to previous buffer" })
vim.keymap.set("n", "<leader>u", "gg=G``", { desc = "Indent buffer" })

vim.keymap.set("n", "<leader>c", function()
    return require("neoclip.fzf")
end, { desc = "FZF clipboard" })

vim.keymap.set("n", "<leader>p", function()
    return require("fzf-lua").builtin()
end, { desc = "FZF builtin" })

vim.keymap.set("n", "<leader>/", function()
    return require("fzf-lua").commands()
end, { desc = "FZF commands" })

vim.keymap.set("n", "<leader>b", function()
    return require("fzf-lua").buffers()
end, { desc = "FZF buffers" })

-- Grep a single pattern.
vim.keymap.set("n", "<leader>g", function()
    return require("fzf-lua").live_grep()
end, { desc = "FZF live_grep" })

-- Grep all words separately, including filename.
vim.keymap.set("n", "<leader>a", function()
    return require("fzf-lua").grep_project({ fzf_opts = { ["--nth"] = false } })
end, { desc = "FZF grep_project" })

vim.keymap.set("n", "<leader>o", function()
    return require("fzf-lua").files()
end, { desc = "FZF files" })

vim.keymap.set("n", "<leader>T", function()
    return require("fzf-lua").tags()
end, { desc = "FZF tags" })

vim.keymap.set("n", "<leader>f", function()
    return require("fzf-lua").lsp_document_symbols()
end, { desc = "FZF lsp_document_symbols" })

vim.keymap.set("n", "<leader>F", function()
    return require("fzf-lua").lsp_live_workspace_symbols()
end, { desc = "FZF lsp_live_workspace_symbols" })

vim.keymap.set("n", "<leader>G", function()
    return require("fzf-lua").git_bcommits()
end, { desc = "FZF git_bcommits" })

-- vim.keymap.set("n", "<leader>B", ":Gblame<CR>", opts)
vim.keymap.set("n", "<leader>W", ":Gw!<CR>", { desc = "Select the current buffer when resolving git conflicts" })
vim.keymap.set("n", "<leader>V", ":SymbolsOutline<CR>", { desc = "Toggle LSP symbols outline tree" })

vim.keymap.set("n", "<leader>l", function()
    if vim.wo.scrolloff > 0 then
        vim.wo.scrolloff = 0
    else
        vim.wo.scrolloff = 999
    end
end, { desc = "Toggle cursor lock" })

vim.keymap.set("n", "<leader>K", "<C-w>K<CR>", { desc = "Align windows vertically" })
vim.keymap.set("n", "<leader>H", "<C-w>H<CR>", { desc = "Align windows horizontally" })

vim.keymap.set("n", "<leader>mt", ":tabm +1<CR>", { desc = "Move tab to right" })
vim.keymap.set("n", "<leader>mT", ":tabm -1<CR>", { desc = "Move tab to left" })

for i = 1, 9 do
    vim.keymap.set(
        "n",
        string.format("<leader>%d", i),
        string.format("%dgt", i),
        { desc = string.format("Goto %dth tab", i) }
    )
end
vim.keymap.set("n", "<leader>0", ":tablast<CR>", { desc = "Goto last tab" })

vim.keymap.set("n", "gj", vim.diagnostic.goto_next, { desc = "Goto next diagnostic" })
vim.keymap.set("n", "gk", vim.diagnostic.goto_prev, { desc = "Goto prev diagnostic" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
vim.keymap.set("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "gD", vim.lsp.buf.implementation, { desc = "Show implementations" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })

vim.keymap.set("n", "gn", function()
    return require("illuminate").goto_next_reference(false)
end, { desc = "Goto next reference" })

vim.keymap.set("n", "gp", function()
    return require("illuminate").goto_prev_reference(false)
end, { desc = "Goto prev reference" })

vim.api.nvim_set_keymap("n", "gc", "<Plug>kommentary_motion_default", { desc = "Toggle comment" })
vim.api.nvim_set_keymap("v", "gc", "<Plug>kommentary_visual_default<C-c>", { desc = "Toggle comment" })

vim.api.nvim_create_user_command("GenerateKeymapDocs", function()
    local mappings = {}

    -- Filter our own custom mappings.
    for _, mode in ipairs({ "i", "t", "n", "v" }) do
        for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
            if type(m.desc) == "string" then
                if
                    -- Does not have <Plug> prefix.
                    m.lhs:find("<Plug>", 1, true) ~= 1
                    and m.mode ~= "x"
                    and string.len(m.desc) > 0
                    and m.desc ~= "Nvim builtin"
                then
                    table.insert(mappings, m)
                end
            end
        end
    end

    -- Sort the mappings.
    table.sort(mappings, function(m1, m2)
        return m1.lhs < m2.lhs
    end)

    -- Generate a table.
    local table_gen = require("table_gen")
    local headings = { "mode", "lhs", "rhs", "desc" }
    local rows = {}

    for _, m in ipairs(mappings) do
        table.insert(rows, {
            string.format("`%s`", m.mode),
            string.format("`%s`", m.lhs),
            -- rhs may contain 2 backticks, escape with 3
            m.rhs and string.format("``` %s ```", m.rhs) or "",
            m.desc,
        })
    end

    local table_out = table_gen(rows, headings, {
        style = "Markdown (Github)",
    })

    local file_path = vim.fn.stdpath("config") .. "/KEYMAP.md"
    local log_file = assert(io.open(file_path, "w"))
    assert(io.output(log_file))
    assert(io.write("## Neovim keymap (generated by `GenerateKeymapDocs` command)\n\n"))
    assert(io.write(table_out .. "\n"))
    assert(io.close(log_file))
end, {})
