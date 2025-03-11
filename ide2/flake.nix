{
  description = "ide2";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      base_pkgs = [
        pkgs.bash
        pkgs.bash-completion
        pkgs.git
        pkgs.delta
        pkgs.unzip
        pkgs.wget
        pkgs.tmux
        pkgs.tree
        pkgs.ripgrep
        pkgs.fd
        pkgs.bat
        pkgs.fzf
        pkgs.glow
        pkgs.parallel
        pkgs.moreutils
        pkgs.shfmt
        pkgs.gh
        pkgs.yamllint
        pkgs.direnv
        pkgs.buf
        pkgs.man
        pkgs.neovim
        pkgs.gojq
        pkgs.hadolint
        pkgs.shellcheck
        pkgs.jsonnet-language-server
        pkgs.docker-compose-language-service
        pkgs.bash-language-server
        pkgs.nodePackages.cspell
        pkgs.markdownlint-cli
        pkgs.nodePackages.prettier
      ];
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      devShells.${system} = {
        base = pkgs.mkShell {
          packages = [
            base_pkgs
          ];

          shellHook = ''
            exec bash
          '';
        };

        go = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.go_1_24
            pkgs.gopls
            pkgs.revive
          ];

          shellHook = ''
            exec bash
          '';
        };

        lua = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.lua-language-server
            pkgs.luajitPackages.luacheck
            pkgs.stylua
          ];

          shellHook = ''
            exec bash
          '';
        };

        rust = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.rustc
            pkgs.rustfmt
            pkgs.clippy
            pkgs.rust-analyzer
          ];

          shellHook = ''
            exec bash
          '';
        };

        php = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.php84
            pkgs.phpactor
            pkgs.php84Extensions.sqlite3
            pkgs.php84Packages.composer
            pkgs.php84Packages.phpstan
            # TODO: laravel/pint
          ];

          shellHook = ''
            exec bash
          '';
        };

        python = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.pipx
          ];

          shellHook = ''
            exec bash
          '';
        };

        webdev = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.html-tidy
            pkgs.nodejs_23
            pkgs.npm-check-updates
            pkgs.pnpm
            pkgs.typescript
            pkgs.typescript-language-server
            pkgs.vscode-langservers-extracted
          ];

          shellHook = ''
            exec bash
          '';
        };
      };

      # packages.${system}.default = pkgs.bash;
    };
}
