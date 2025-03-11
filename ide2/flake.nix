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

    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [
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
            pkgs.html-tidy
            pkgs.nodejs_23
            pkgs.go
            pkgs.gopls
            pkgs.revive
            pkgs.shfmt
            pkgs.gh
            pkgs.buf
            pkgs.yamllint
            pkgs.direnv
            pkgs.lua-language-server
            pkgs.luajitPackages.luacheck
            pkgs.stylua
            pkgs.rtmidi
            pkgs.php84
            pkgs.php84Extensions.sqlite3
            pkgs.php84Packages.composer
            pkgs.rustc
            pkgs.rustfmt
            pkgs.clippy
            pkgs.rust-analyzer
            pkgs.man
            pkgs.pipx
            pkgs.neovim
            pkgs.gojq
            pkgs.hadolint
            pkgs.shellcheck
          ];

          shellHook = ''
            exec bash
          '';
        };
      };

      # packages.${system}.default = pkgs.bash;
    };
}
