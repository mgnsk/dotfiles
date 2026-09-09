{ pkgs, inputs, ... }:
let
  nvimPlugins =
    (with inputs; [
      nvim-plugin-autotabline
      nvim-plugin-dumb-autopairs
      nvim-plugin-nvim-fundo
      nvim-plugins-tree-sitter-balafon.packages.x86_64-linux.nvimParser
    ])
    ++ (with pkgs.vimPlugins; [
      SchemaStore-nvim
      blink-cmp
      conform-nvim
      fzf-lua
      gitsigns-nvim
      luvit-meta
      nvim-ansible
      nvim-colorizer-lua
      nvim-lint
      nvim-lspconfig
      oil-nvim
      promise-async
      vim-fugitive
      vim-jsonpath
      vim-wordmotion
      vscode-nvim
    ])
    ++ (with pkgs.vimPlugins.nvim-treesitter-parsers; [
      authzed
      bash
      beancount
      c
      caddy
      comment
      cpp
      css
      csv
      desktop
      diff
      dockerfile
      ebnf
      faust
      git_config
      git_rebase
      gitcommit
      gitignore
      glsl
      go
      gomod
      gosum
      gotmpl
      gowork
      graphql
      helm
      html
      ini
      javascript
      jq
      jsdoc
      json
      json5
      jsonnet
      lalrpop
      ledger
      lua
      luadoc
      make
      markdown
      markdown_inline
      mermaid
      nginx
      nix
      php
      phpdoc
      po
      proto
      python
      regex
      scss
      sql
      ssh_config
      sway
      tlaplus
      toml
      tsx
      twig
      typescript
      vim
      vimdoc
      xml
      yaml
    ]);

  nvimPluginsPack = pkgs.stdenv.mkDerivation {
    name = "mgnsk-neovim-plugins";
    buildCommand = ''
      mkdir -p $out/pack/plugins/start/
      ${pkgs.lib.concatMapStringsSep "\n" (path: "ln -s ${path} $out/pack/plugins/start/") nvimPlugins}
    '';
  };

  myneovim = pkgs.neovim.override {
    wrapperArgs = [
      "--add-flags"
      # Contains the queries/ dir.
      ''--cmd "set rtp^=${inputs.nvim-plugin-tree-sitter-manager}/runtime"''

      # Add the plugin pack to packpath.
      "--add-flags"
      ''--cmd "set packpath^=${nvimPluginsPack.outPath}"''
    ];
  };
in
{
  home.packages = [ myneovim ];
}
