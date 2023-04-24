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

    if buf_count == 1 then
        vim.cmd("q!")
    else
        vim.cmd("bd!")
    end
end, { desc = "Kill buffer" })

set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

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
set("n", "<leader>w", ":set wrap!<CR>", { desc = "Toggle word wrap" })

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

set("n", "<leader>H", function()
    return require("fzf-lua").git_commits()
end, { desc = "FZF git_commits" })

set("n", "<leader>B", ":Git blame<CR>", { desc = "Git blame" })
set("n", "<leader>W", ":Gw!<CR>", { desc = "Select the current buffer when resolving git conflicts" })

set("n", "<leader>V", function()
    return require("symbols-outline").toggle_outline()
end, { desc = "Toggle LSP symbols outline tree" })

set("n", "<leader>l", function()
    if vim.wo.scrolloff > 0 then
        vim.wo.scrolloff = 0
    else
        vim.wo.scrolloff = 999
    end
end, { desc = "Toggle cursor lock" })

set("n", "<leader>mt", ":tabm +1<CR>", { desc = "Move tab to right" })
set("n", "<leader>mT", ":tabm -1<CR>", { desc = "Move tab to left" })

for i = 1, 9 do
    set("n", string.format("<leader>%d", i), string.format("%dgt", i), { desc = string.format("Goto %dth tab", i) })
end
set("n", "<leader>0", ":tablast<CR>", { desc = "Goto last tab" })

local function reverse(t)
    for i = 1, math.floor(#t / 2) do
        local j = #t - i + 1
        t[i], t[j] = t[j], t[i]
    end
end

local function sort_loclist(loclist)
    table.sort(loclist, function(a, b)
        if a.lnum < b.lnum then
            return true
        elseif a.lnum > b.lnum then
            return false
        end

        return a.col < b.col
    end)
end

set("n", "gj", function()
    if vim.diagnostic.get_next() then
        vim.diagnostic.goto_next()
        return
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local bufnr = vim.api.nvim_get_current_buf()
    local loclist = vim.fn.getloclist(0)
    sort_loclist(loclist)

    for _, entry in pairs(loclist) do
        if entry.bufnr == bufnr then
            if entry.lnum == row and entry.col > col or entry.lnum > row then
                vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
                return
            end
        end
    end

    vim.api.nvim_echo({ { "No more valid diagnostics or location list items to move to", "WarningMsg" } }, true, {})
end, { desc = "Goto next diagnostic or location list item in current buffer" })

set("n", "gk", function()
    if vim.diagnostic.get_prev() then
        vim.diagnostic.goto_prev()
        return
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local bufnr = vim.api.nvim_get_current_buf()
    local loclist = vim.fn.getloclist(0)
    sort_loclist(loclist)
    reverse(loclist)

    for _, entry in pairs(loclist) do
        if entry.bufnr == bufnr then
            if entry.lnum == row and entry.col < col or entry.lnum < row then
                vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
                return
            end
        end
    end

    vim.api.nvim_echo({ { "No more valid diagnostics or location list items to move to", "WarningMsg" } }, true, {})
end, { desc = "Goto prev diagnostic or location list item in current buffer" })

set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
set("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })
set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
set("n", "L", vim.diagnostic.open_float, { desc = "Hover diagnostic" })
set("n", "gD", vim.lsp.buf.implementation, { desc = "Show implementations" })
set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })

set("n", "<leader>S", function()
    if vim.o.spell then
        vim.o.spell = false
        print("spell off")
    else
        vim.o.spell = true
        print("spell on")
    end
end, { desc = "Toggle spell check" })

local function escape_backticks(s)
    local _, backtick_count = string.gsub(s, "`", "")
    local ticks = string.rep("`", backtick_count + 1)
    return string.format("%s %s %s", ticks, s, ticks)
end

vim.api.nvim_create_user_command("MarkdownPreview", function()
    vim.cmd("Glow")
end, { desc = "Markdown preview" })

vim.api.nvim_create_user_command("GenerateKeymapDocs", function()
    -- Generate a table.
    local table_gen = require("table_gen")
    local headings = { "mode", "lhs", "rhs", "desc" }
    local rows = {}

    for _, m in ipairs(vim.api.nvim_get_keymap("")) do
        if m.lhs:find("<Plug>", 1, true) ~= 1 then
            table.insert(rows, {
                string.format("`%s`", m.mode),
                string.format("`%s`", m.lhs),
                m.rhs and escape_backticks(m.rhs) or "",
                m.desc,
            })
        end
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
