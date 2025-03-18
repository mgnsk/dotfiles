{
  description = "ide";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    blink-cmp.url = "git+file:/home/magnus/.config/nvim/plugins/blink.cmp";
    dotfiles-src = {
      url = "git+file:/home/magnus?submodules=1";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      blink-cmp,
      dotfiles-src,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Create a wrapper derivation for blink-cmp.
      blink = pkgs.stdenv.mkDerivation {
        pname = "blink-cmp-wrapper";
        version = "1.0.0";

        src = blink-cmp;

        buildInputs = [ blink-cmp.packages.${system}.blink-fuzzy-lib ];

        installPhase = ''
          mkdir -p $out/lib
          cp ${
            blink-cmp.packages.${system}.blink-fuzzy-lib
          }/lib/libblink_cmp_fuzzy.so $out/lib/blink_cmp_fuzzy.so
        '';
      };

      # Define common shell hook as a function
      commonShellHook = customHost: ''
        export LUA_CPATH="${blink}/lib/?.so"
        export CUSTOM_HOST="${customHost}"
        exec bash
      '';

      base_pkgs = [
        pkgs.glibcLocalesUtf8
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
        pkgs.coreutils
        pkgs.moreutils
        pkgs.which
        pkgs.shfmt
        pkgs.gh
        pkgs.yamllint
        pkgs.direnv
        pkgs.buf
        pkgs.man
        pkgs.neovim
        pkgs.gcc
        pkgs.gojq
        pkgs.hadolint
        pkgs.shellcheck
        pkgs.jsonnet-language-server
        pkgs.docker-compose-language-service
        pkgs.bash-language-server
        pkgs.nodejs_23
        pkgs.nodePackages.cspell
        pkgs.markdownlint-cli
        pkgs.nodePackages.prettier
        pkgs.nil
        pkgs.nixfmt-rfc-style
      ];

      go_pkgs = [
        pkgs.go_1_24
        pkgs.gopls
        pkgs.revive
      ];

      lua_pkgs = [
        pkgs.go_1_24
        pkgs.lua-language-server
        pkgs.luajitPackages.luacheck
        pkgs.stylua
      ];

      rust_pkgs = [
        pkgs.rustc
        pkgs.rustfmt
        pkgs.clippy
        pkgs.rust-analyzer
      ];

      php_pkgs = [
        pkgs.php84
        pkgs.phpactor
        pkgs.php84Extensions.sqlite3
        pkgs.php84Packages.composer
        pkgs.php84Packages.phpstan
        # TODO: laravel/pint
      ];

      python_pkgs = [
        pkgs.pipx
      ];

      webdev_pkgs = [
        pkgs.html-tidy
        pkgs.npm-check-updates
        pkgs.pnpm
        pkgs.typescript
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
      ];

      docker_user = "ide";
      docker_group = "ide";
      docker_uid = "1000";
      docker_gid = "1000";
    in
    {
      docker = pkgs.dockerTools.buildImage {
        name = "ghcr.io/mgnsk/ide";
        tag = "edge";

        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = base_pkgs ++ go_pkgs ++ lua_pkgs ++ rust_pkgs ++ php_pkgs ++ python_pkgs ++ webdev_pkgs;
          pathsToLink = [ "/bin" ];
        };

        runAsRoot = ''
          #!${pkgs.runtimeShell}
          ${pkgs.dockerTools.shadowSetup}
          groupadd -f -g ${docker_gid} ${docker_group}
          useradd -m -s /bin/bash -g ${docker_group} --uid ${docker_uid} ${docker_user}
          passwd -d ${docker_user}

          shopt -s dotglob
          cp -r ${dotfiles-src}/* /home/${docker_user}/
          chown -R ${docker_user}:${docker_group} /home/${docker_user}/

          install -d -m 0755 --owner=${docker_user} --group=${docker_group} \
              /home/${docker_user}/.cache \
              /home/${docker_user}/.cargo \
              /home/${docker_user}/.local/share/nvim \
              /home/${docker_user}/.local/state \
              /home/${docker_user}/go/bin \
              /home/${docker_user}/go/pkg

          mkdir -p /usr/lib/locale
          cp -r ${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive /usr/lib/locale/locale-archive
          echo "LANG=en_US.UTF-8" > /etc/locale.conf
        '';

        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ];
          User = "${docker_uid}:${docker_gid}";
          Env = [
            "LUA_CPATH=${blink}/lib/?.so"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
        };
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [
            base_pkgs
            go_pkgs
            lua_pkgs
            rust_pkgs
            php_pkgs
            python_pkgs
            webdev_pkgs
          ];
          shellHook = commonShellHook "ide-default";
        };

        base = pkgs.mkShell {
          packages = [
            base_pkgs
          ];
          shellHook = commonShellHook "ide-base";
        };

        go = pkgs.mkShell {
          packages = [
            base_pkgs
            go_pkgs
          ];
          shellHook = commonShellHook "ide-go";
        };

        lua = pkgs.mkShell {
          packages = [
            base_pkgs
            lua_pkgs
          ];
          shellHook = commonShellHook "ide-lua";
        };

        rust = pkgs.mkShell {
          packages = [
            base_pkgs
            rust_pkgs
          ];
          shellHook = commonShellHook "ide-rust";
        };

        php = pkgs.mkShell {
          packages = [
            base_pkgs
            php_pkgs
          ];
          shellHook = commonShellHook "ide-php";
        };

        python = pkgs.mkShell {
          packages = [
            base_pkgs
            python_pkgs
          ];
          shellHook = commonShellHook "ide-python";
        };

        webdev = pkgs.mkShell {
          packages = [
            base_pkgs
            webdev_pkgs
          ];
          shellHook = commonShellHook "ide-webdev";
        };
      };

      # packages.${system}.default = pkgs.bash;
    };
}
