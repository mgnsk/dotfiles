{
  description = "ide";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    blink-cmp.url = "git+file:/home/magnus/.config/nvim/plugins/blink.cmp";
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Create a wrapper derivation for blink-cmp.
      blink = pkgs.stdenv.mkDerivation {
        pname = "blink-cmp-wrapper";
        version = "1.0.0";

        src = inputs.blink-cmp;

        buildInputs = [ inputs.blink-cmp.packages.${system}.blink-fuzzy-lib ];

        installPhase = ''
          mkdir -p $out/lib
          cp ${
            inputs.blink-cmp.packages.${system}.blink-fuzzy-lib
          }/lib/libblink_cmp_fuzzy.so $out/lib/blink_cmp_fuzzy.so
        '';
      };

      base_pkgs = [
        pkgs.glibcLocalesUtf8
        pkgs.ncurses
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gawk
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
        pkgs.coreutils
        pkgs.moreutils
        pkgs.which
        pkgs.shfmt
        pkgs.direnv
        pkgs.man
        pkgs.vim
      ];

      dev_pkgs = [
        pkgs.neovim
        pkgs.gojq
        pkgs.shellcheck
        pkgs.hadolint
        pkgs.gcc
        pkgs.buf
        pkgs.yamllint
        pkgs.gh
        pkgs.glow
        pkgs.jsonnet-language-server
        pkgs.docker-compose-language-service
        pkgs.bash-language-server
        pkgs.nodejs_22
        pkgs.nodePackages.cspell
        pkgs.markdownlint-cli
        pkgs.nodePackages.prettier
        pkgs.nil
        pkgs.nixfmt-rfc-style
        pkgs.ansible
        pkgs.ansible-lint
        pkgs.ansible-language-server
      ];

      go_pkgs = [
        pkgs.go_1_24
        pkgs.gopls
        pkgs.revive
      ];

      lua_pkgs = [
        pkgs.lua-language-server
        pkgs.luajitPackages.luacheck
        pkgs.stylua
      ];

      rust_pkgs = [
        pkgs.rustc
        pkgs.rustfmt
        pkgs.clippy
        pkgs.rust-analyzer
        pkgs.cargo
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
        pkgs.pipenv
        pkgs.black
        pkgs.pylint
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
          paths =
            base_pkgs ++ dev_pkgs ++ go_pkgs ++ lua_pkgs ++ rust_pkgs ++ php_pkgs ++ python_pkgs ++ webdev_pkgs;
          pathsToLink = [ "/bin" ];
        };

        runAsRoot = ''
          #!${pkgs.runtimeShell}
          ${pkgs.dockerTools.shadowSetup}
          groupadd -f -g ${docker_gid} ${docker_group}
          useradd -m -s /bin/bash -g ${docker_group} --uid ${docker_uid} ${docker_user}
          passwd -d ${docker_user}

          cp -a ${self}/. /home/${docker_user}/
          chown -R ${docker_user}:${docker_group} /home/${docker_user}/

          install -d -m 0755 --owner=${docker_user} --group=${docker_group} \
              /home/${docker_user}/.cache \
              /home/${docker_user}/.cargo \
              /home/${docker_user}/.local \
              /home/${docker_user}/.local/share \
              /home/${docker_user}/.local/state

          mkdir -p /usr/lib/locale
          cp -a ${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive /usr/lib/locale/locale-archive
          echo "LANG=en_US.UTF-8" > /etc/locale.conf
        '';

        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ];
          User = "${docker_uid}:${docker_gid}";
          Env = [
            "LUA_CPATH=${blink}/lib/?.so"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            "TZDIR=${pkgs.tzdata}/share/zoneinfo"
          ];
        };
      };

      devShells.${system} = {
        base = pkgs.mkShell {
          packages = [
            base_pkgs
          ];
          shellHook = ''
            export CUSTOM_HOST="ide-base"
            exec bash
          '';
        };

        dev = pkgs.mkShell {
          packages = [
            base_pkgs
            dev_pkgs
            go_pkgs
            lua_pkgs
            rust_pkgs
            php_pkgs
            python_pkgs
            webdev_pkgs
          ];
          shellHook = ''
            export LUA_CPATH="${blink}/lib/?.so"
            export CUSTOM_HOST="ide-dev"
            exec bash
          '';
        };

        audio = pkgs.mkShell {
          packages = [
            base_pkgs
            pkgs.reaper
            pkgs.yabridge
            pkgs.yabridgectl
            pkgs.wineWowPackages.yabridge
          ];
          shellHook = ''
            export CUSTOM_HOST="ide-audio"
            exec bash
          '';
        };
      };
    };
}
