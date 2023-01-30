local function set(mode, lhs, rhs, opts_overrides)
    local opts = { noremap = true, silent = true }
    opts = vim.tbl_extend("force", opts, opts_overrides or {})
    vim.keymap.set(mode, lhs, rhs, opts)
end

vim.g.mapleader = ","

set("v", "Y", [["+y<CR>]], { desc = "Big yank (system clipboard)" })
set("i", "jj", "<Esc>", { desc = "Escape from insert mode" })
set("t", "jj", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
set("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

set("n", "qq", function()
    local buf_count = #(vim.fn.getbufinfo({ buflisted = 1 }))

    if vim.fn.expand("%") == "" and buf_count == 1 then
        vim.cmd("q!")
    else
        vim.cmd("bd!")
    end
end, { desc = "Kill buffer" })

set("n", "<C-h>", "<C-w>h", { desc = "Goto to left window" })
set("n", "<C-j>", "<C-w>j", { desc = "Goto bottom window" })
set("n", "<C-k>", "<C-w>k", { desc = "Goto upper window" })
set("n", "<C-l>", "<C-w>l", { desc = "Goto right window" })

set("n", "<leader>.", ":", { desc = "Command mode", silent = false })
set(
    "n",
    "<leader>,",
    ":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>",
    { desc = "Open new terminal window to right" }
)
set("n", "tt", ":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>", { desc = "Open new terminal tab" })
set("n", "<leader>v", ":vnew<CR>", { desc = "Open new window to right" })
set("n", "<leader>s", ":new<CR>", { desc = "Open new window to bottom" })
set("n", "<leader>t", ":tabnew<CR>", { desc = "Open new tab" })
set("n", "<leader>e", ":Tex<CR>", { desc = "Open file browser in new tab" })
set("n", "<leader>j", ":bnext<CR>", { desc = "Switch to next buffer" })
set("n", "<leader>k", ":bprev<CR>", { desc = "Switch to previous buffer" })
set("n", "<leader>u", "gg=G``", { desc = "Indent buffer" })

set("n", "<leader>c", function()
    return require("neoclip.fzf")
end, { desc = "FZF clipboard" })

set("n", "<leader>p", function()
    return require("fzf-lua").builtin()
end, { desc = "FZF builtin" })

set("n", "<leader>/", function()
    return require("fzf-lua").commands()
end, { desc = "FZF commands" })

set("n", "<leader>b", function()
    return require("fzf-lua").buffers()
end, { desc = "FZF buffers" })

-- Grep a single pattern.
set("n", "<leader>g", function()
    return require("fzf-lua").live_grep()
end, { desc = "FZF live_grep" })

-- Grep all words separately, including filename.
set("n", "<leader>a", function()
    return require("fzf-lua").grep_project({ fzf_opts = { ["--nth"] = false } })
end, { desc = "FZF grep_project" })

set("n", "<leader>o", function()
    return require("fzf-lua").files()
end, { desc = "FZF files" })

set("n", "<leader>T", function()
    return require("fzf-lua").tags()
end, { desc = "FZF tags" })

set("n", "<leader>f", function()
    return require("fzf-lua").lsp_document_symbols()
end, { desc = "FZF lsp_document_symbols" })

set("n", "<leader>F", function()
    return require("fzf-lua").lsp_live_workspace_symbols()
end, { desc = "FZF lsp_live_workspace_symbols" })

set("n", "<leader>G", function()
    return require("fzf-lua").git_bcommits()
end, { desc = "FZF git_bcommits" })

-- set("n", "<leader>B", ":Gblame<CR>", opts)
set("n", "<leader>W", ":Gw!<CR>", { desc = "Select the current buffer when resolving git conflicts" })
set("n", "<leader>V", ":SymbolsOutline<CR>", { desc = "Toggle LSP symbols outline tree" })

set("n", "<leader>l", function()
    if vim.wo.scrolloff > 0 then
        vim.wo.scrolloff = 0
    else
        vim.wo.scrolloff = 999
    end
end, { desc = "Toggle cursor lock" })

set("n", "<leader>K", "<C-w>K<CR>", { desc = "Align windows vertically" })
set("n", "<leader>H", "<C-w>H<CR>", { desc = "Align windows horizontally" })

set("n", "<leader>mt", ":tabm +1<CR>", { desc = "Move tab to right" })
set("n", "<leader>mT", ":tabm -1<CR>", { desc = "Move tab to left" })

for i = 1, 9 do
    set("n", string.format("<leader>%d", i), string.format("%dgt", i), { desc = string.format("Goto %dth tab", i) })
end
set("n", "<leader>0", ":tablast<CR>", { desc = "Goto last tab" })

set("n", "gj", vim.diagnostic.goto_next, { desc = "Goto next diagnostic" })
set("n", "gk", vim.diagnostic.goto_prev, { desc = "Goto prev diagnostic" })
set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
set("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })
set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
set("n", "gD", vim.lsp.buf.implementation, { desc = "Show implementations" })
set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })

set("n", "gn", function()
    return require("illuminate").goto_next_reference(false)
end, { desc = "Goto next reference" })

set("n", "gp", function()
    return require("illuminate").goto_prev_reference(false)
end, { desc = "Goto prev reference" })

set("n", "gc", "<Plug>kommentary_motion_default", { desc = "Toggle comment" })
set("v", "gc", "<Plug>kommentary_visual_default<C-c>", { desc = "Toggle comment" })

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
