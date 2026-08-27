# nvim config

Personal Neovim config. No plugin manager — see "Plugins" below.

## Layout

| Path | Contents |
|---|---|
| `init.lua` | Global options, mapleader, clipboard, generic keymaps, then loads everything under `lua/` |
| `lua/*.lua` | One file per feature/plugin (colors, completion, git, lsp, ...), each mixing its own options/keymaps/autocmds/plugin setup |
| `lsp/*.lua` | Per-server `vim.lsp.config` tables, auto-loaded by Neovim 0.11+'s native LSP config convention |
| `ftplugin/*.lua` | Per-filetype settings (indent, formatters, linters) |
| `ftdetect/*.lua` | Custom filetype detection for filetypes Neovim doesn't recognize out of the box |
| `snippets/*.json` | VS Code-style snippets |

## LSP: `lsp/*.lua` vs `lua/lsp.lua`

These are two different layers, not duplication:

- `lsp/*.lua` are per-server config tables (`cmd`, `root_dir`, `settings`, ...), one file per server that needs overrides beyond nvim-lspconfig's bundled defaults. Only a few of the enabled servers have a file here — the rest inherit nvim-lspconfig's defaults directly (its own `lsp/*.lua` files ship on the runtimepath and are picked up by name).
- `lua/lsp.lua` is the editor-level glue: capabilities (wired to blink.cmp), keymaps (`gd`, `gr`, `<leader>rn`, ...), the `LspAttach` autocmd, and the `vim.lsp.enable({...})` call that actually turns servers on.

## Plugins

There is no plugin manager (no lazy.nvim/packer). Plugins are declared as Nix flake inputs in `~/flake.nix` and symlinked onto `packpath` via home-manager. This repo only *configures* plugins that are already installed — `init.lua`'s `packloadall()` + `require(...)` calls never install anything. To add/remove a plugin, edit `~/flake.nix`, not this repo.

## Notable patterns

- Some `ftplugin/*.lua` files (e.g. `jsonc.lua`, `sh.lua`) are one-line filetype reassignments (`vim.bo.filetype = "json"`) that alias a filetype onto an existing one's config, rather than duplicating indent/formatter/linter wiring for a near-identical filetype.
- `util.in_diff_mode()` (`lua/util.lua`) checks the `NVIM_DIFF` env var, used to skip interactive-only setup (LSP, formatters, linters, completion) when Neovim is running as a `git difftool` helper.
