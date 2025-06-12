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

      base_pkgs = with pkgs; [
        glibcLocalesUtf8
        ncurses
        gnugrep
        gnused
        gawk
        bash
        bash-completion
        git
        unzip
        wget
        tmux
        tree
        ripgrep
        fd
        bat
        fzf
        coreutils
        moreutils
        which
        shfmt
        direnv
        man
        vim
        qrcp
        file
      ];

      dev_pkgs = with pkgs; [
        neovim
        gojq
        shellcheck
        hadolint
        gcc
        buf
        yamllint
        gh
        glow
        jsonnet-language-server
        docker-compose-language-service
        bash-language-server
        nodejs_22
        nodePackages.cspell
        markdownlint-cli
        nodePackages.prettier
        nil
        nixfmt-rfc-style
        ansible
        ansible-lint
        ansible-language-server
      ];

      go_pkgs = with pkgs; [
        go_1_24
        gopls
        revive
      ];

      lua_pkgs = with pkgs; [
        lua-language-server
        luajitPackages.luacheck
        stylua
      ];

      rust_pkgs = with pkgs; [
        rustc
        rustfmt
        clippy
        rust-analyzer
        cargo
      ];

      php_pkgs = with pkgs; [
        php84
        phpactor
        php84Extensions.sqlite3
        php84Packages.composer
        php84Packages.phpstan
        # TODO: laravel/pint
      ];

      python_pkgs = with pkgs; [
        pipx
        pipenv
        black
        pylint
      ];

      webdev_pkgs = with pkgs; [
        html-tidy
        npm-check-updates
        pnpm
        typescript
        typescript-language-server
        vscode-langservers-extracted
      ];

      audio_pkgs = with pkgs; [
        pipewire.jack
        raysession
        reaper
        reaper-reapack-extension
        yabridge
        yabridgectl
        tuxguitar
        wineWowPackages.yabridge
        winetricks
        cabextract
        zam-plugins
        lsp-plugins
        chow-tape-model
        fluidsynth
        libsndfile.out
        liblo
      ];

      docker_user = "ide";
      docker_group = "ide";
      docker_uid = "1000";
      docker_gid = "1000";
    in
    {
      docker = pkgs.dockerTools.streamLayeredImage {
        name = "ghcr.io/mgnsk/ide";
        tag = "edge";

        contents = [
          base_pkgs
          dev_pkgs
          go_pkgs
          lua_pkgs
          rust_pkgs
          php_pkgs
          python_pkgs
          webdev_pkgs
        ];

        enableFakechroot = true;
        fakeRootCommands = ''
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

      devShells.${system} = with pkgs; {
        base = mkShell {
          buildInputs = [
            base_pkgs
          ];
          shellHook = ''
            export CUSTOM_HOST="ide-base"
            export PATH="${git}/share/git/contrib/diff-highlight:$PATH"

            exec bash
          '';
        };

        dev = mkShell {
          buildInputs = [
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
            export CUSTOM_HOST="ide-dev"
            export PATH="${git}/share/git/contrib/diff-highlight:$PATH"
            export LUA_CPATH="${blink}/lib/?.so"

            exec bash
          '';
        };

        audio = mkShell {
          buildInputs = [
            base_pkgs
            audio_pkgs
          ];
          shellHook = ''
            export CUSTOM_HOST="ide-audio"
            export PATH="${git}/share/git/contrib/diff-highlight:$PATH"

            export CLAP_PATH="${zam-plugins}/lib/clap;$CLAP_PATH"
            export CLAP_PATH="${lsp-plugins}/lib/clap;$CLAP_PATH"
            export CLAP_PATH="${chow-tape-model}/lib/clap;$CLAP_PATH"

            export LD_LIBRARY_PATH="${
              lib.makeLibraryPath (
                builtins.concatLists [
                  audio_pkgs
                ]
              )
            }:$LD_LIBRARY_PATH"

            export NIX_PROFILES="${yabridge} $NIX_PROFILES"

            # TODO: needs a wine build with fsync patch.
            export WINEFSYNC=1

            # Make reapack available.
            mkdir -p ~/.config/REAPER/UserPlugins
            ln -sf ${reaper-reapack-extension}/UserPlugins/* ~/.config/REAPER/UserPlugins/

            yabridgectl add ~/win-plugins
            yabridgectl add ~/.wine/drive_c/Program\ Files/Common\ Files/VST3
            yabridgectl sync
            yabridgectl status

            exec bash
          '';
        };
      };
    };
}
