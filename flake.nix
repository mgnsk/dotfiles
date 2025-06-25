{
  description = "ide";

  inputs = {
    dev-nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Separate input for audio packages so we can update dev and audio shells independently.
    audio-nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";

      # Packages for dev shell.
      pkgs = import inputs.dev-nixpkgs {
        inherit system;
      };

      diff-highlight = pkgs.linkFarm "diff-highlight" [
        {
          name = "bin/diff-highlight";
          path = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
        }
      ];

      base_pkgs = with pkgs; [
        glibcLocalesUtf8
        ncurses
        gnugrep
        gnused
        gawk
        bash
        bash-completion
        git
        diff-highlight
        less
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
        neovim
        qrcp
        file
      ];

      gh-tpl = pkgs.stdenv.mkDerivation {
        name = "gh-tpl";
        src = pkgs.fetchurl {
          url = "https://github.com/mgnsk/gh-tpl/releases/download/v0.0.6/gh-tpl-v0.0.6-linux-amd64.tar.gz";
          sha256 = "f08b9e725601c32c9867172679a5c260dc0e1d4a553b1263e1e41830fcc1d775";
        };
        sourceRoot = ".";
        installPhase = ''
          install -m755 -D gh-tpl $out/bin/gh-tpl
        '';
      };

      tusk-go = pkgs.stdenv.mkDerivation {
        name = "tusk-go";
        src = pkgs.fetchurl {
          url = "https://github.com/rliebz/tusk/releases/download/v0.7.3/tusk_0.7.3_linux_amd64.tar.gz";
          sha256 = "1eb47f2815fd9b59e8def42cf1f1a1c8f369cb7e4124190710e6645876f85b7d";
        };
        sourceRoot = ".";
        installPhase = ''
          install -m755 -D tusk $out/bin/tusk
        '';
      };

      gocc = pkgs.buildGoModule (finalAttrs: {
        pname = "gocc";
        version = "1.0.2";
        src = pkgs.fetchFromGitHub {
          owner = "goccmack";
          repo = "gocc";
          rev = "v${finalAttrs.version}";
          sha256 = "sha256-sBpwxpTAh2f74AUQVEEESgyrtJzOraTTBxTTESbYYGc=";
        };
        vendorHash = "sha256-5uV8i+xngxep+2oOwCjddP56Z36ZeL9BbBcFTl/zE3Y=";
        doCheck = false;
      });

      go_pkgs = with pkgs; [
        go_1_24
        gopls
        revive
        gocc
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

      pint = pkgs.stdenv.mkDerivation {
        name = "pint";
        src = pkgs.fetchurl {
          url = "https://github.com/laravel/pint/releases/download/v1.22.1/pint.phar";
          sha256 = "b70b0e851f58a0884bda550e1021a63affa869ce399173cbe92c50087c45da07";
        };
        phases = [ "installPhase" ]; # Removes all phases except installPhase (no unpackPhase).
        installPhase = ''
          install -m755 -D $src $out/bin/pint
        '';
      };

      php_pkgs = with pkgs; [
        php84
        phpactor
        php84Extensions.sqlite3
        php84Packages.composer
        php84Packages.phpstan
        pint
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
        eslint
        stylelint
        typescript
        typescript-language-server
        vscode-langservers-extracted
      ];

      jsfx-lint = pkgs.stdenv.mkDerivation {
        name = "jsfx-lint";
        src = pkgs.fetchurl {
          url = "https://github.com/Souk21/jsfx-lint/releases/download/0.2.0/jsfx-lint-0.2.0-x86_64-unknown-linux-musl.tar.gz";
          sha256 = "ee20752516341a69d2f7be595834ed754614b5a3638f806580f538c0c66d0a60";
        };
        sourceRoot = "./jsfx-lint-0.2.0-x86_64-unknown-linux-musl";
        installPhase = ''
          install -m755 -D eel_pp $out/bin/eel_pp
          install -m755 -D jsfx-lint $out/bin/jsfx-lint
        '';
      };

      dev_pkgs = with pkgs; [
        base_pkgs

        tusk-go
        gojq
        shellcheck
        hadolint
        gcc
        buf
        yamllint
        gh
        gh-tpl
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
        jsfx-lint

        go_pkgs
        lua_pkgs
        rust_pkgs
        php_pkgs
        python_pkgs
        webdev_pkgs
      ];

      # Packges for audio shell.
      audiopkgs = import inputs.audio-nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      spirv-tools-lib = pkgs.linkFarm "spirv-tools-lib" [
        {
          name = "lib/libSPIRV-Tools.so";
          path = "${audiopkgs.spirv-tools}/lib/libSPIRV-Tools-shared.so";
        }
      ];

      audio_pkgs = with audiopkgs; [
        # Pipewire JACK management.
        pipewire.jack
        raysession

        # For LSP and Zam plugins.
        mesa
        libGL

        # Complete Vulkan setup to fix Northern Artillery Drums plugin GUI not updating until window moved.
        libdrm
        llvmPackages_20.libllvm
        elfutils
        zstd
        xorg.libxcb
        wayland
        libz
        xorg.libX11
        xorg.libxshmfence
        xorg.xcbutilkeysyms
        libudev-zero
        expat
        spirv-tools-lib
        pkgs.stdenv.cc.cc.lib

        # Reaper.
        reaper
        reaper-reapack-extension

        # Wine and yabridge.
        yabridge
        yabridgectl
        wineWow64Packages.yabridge
        winetricks
        cabextract

        # Additional plugins.
        zam-plugins
        lsp-plugins
        chow-tape-model
        guitarix
        gxplugins-lv2
        airwindows
        x42-plugins
        infamousPlugins
        distrho-ports
        mda_lv2
        swh_lv2
        mod-distortion
        kapitonov-plugins-pack
      ];

      docker_user = "ide";
      docker_group = "ide";
      docker_uid = "1000";
      docker_gid = "1000";

      # makeClapPath creates a CLAP_PATH value for Reaper, separated with semicolons.
      makeClapPath =
        paths:
        builtins.concatStringsSep ";" (
          map (path: path + "/lib/clap") (builtins.filter (x: x != null) paths)
        );

      # Symlink LV2 or VST plugins to make them available for Reaper.
      # For some reason Reaper only supports loading CLAP plugins via env vars.
      symlimkPlugins =
        type: paths:
        builtins.concatStringsSep "\n" (
          map (path: ''
            mkdir -p ~/.${type}
            ln -sf ${path}/lib/${type}/* ~/.${type}/
          '') paths
        );

      ensureYabridgePaths =
        paths:
        builtins.concatStringsSep "\n" (
          map (path: ''
            mkdir -p "${path}"
            yabridgectl add "${path}"
          '') paths
        );
    in
    {
      docker = pkgs.dockerTools.streamLayeredImage {
        name = "ghcr.io/mgnsk/ide";
        tag = "edge";
        contents = dev_pkgs;
        enableFakechroot = true;
        fakeRootCommands = ''
          set -e
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
              /home/${docker_user}/.local/state \
              /home/${docker_user}/.npm

          mkdir -p /usr/lib/locale
          cp -a ${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive /usr/lib/locale/locale-archive
          echo "LANG=en_US.UTF-8" > /etc/locale.conf

          # Fixes #!/usr/bin/env shebang in scripts.
          ln -s /bin /usr/bin
        '';

        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ];
          User = "${docker_uid}:${docker_gid}";
          Env = [
            "SHELL=${pkgs.bash}/bin/bash"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            "TZDIR=${pkgs.tzdata}/share/zoneinfo"
          ];
        };
      };

      devShells.${system} = {
        dev = pkgs.mkShellNoCC {
          buildInputs = dev_pkgs;
          shellHook = ''
            export CUSTOM_HOST="ide-dev"
            export SHELL="${pkgs.bash}/bin/bash"
          '';
        };

        audio = pkgs.mkShellNoCC {
          buildInputs = [
            base_pkgs
            audio_pkgs
          ];
          shellHook = with audiopkgs; ''
            set -e

            function cleanup {
              echo "Exiting audio shell"
              wineserver -k || true
            }

            trap cleanup EXIT

            export CUSTOM_HOST="ide-audio"
            export SHELL="${pkgs.bash}/bin/bash"
            export NIX_PROFILES="${yabridge} $NIX_PROFILES"
            export WINEFSYNC=1 # TODO: needs a wine build with fsync patch.

            export CLAP_PATH="${
              makeClapPath [
                zam-plugins
                lsp-plugins
                chow-tape-model
              ]
            };$CLAP_PATH"

            export LD_LIBRARY_PATH="${lib.makeLibraryPath audio_pkgs}:$LD_LIBRARY_PATH"

            ${symlimkPlugins "lv2" [
              guitarix
              gxplugins-lv2
              x42-plugins
              infamousPlugins
              distrho-ports
              mda_lv2
              swh_lv2
              mod-distortion
              kapitonov-plugins-pack
            ]}

            ${symlimkPlugins "vst" [
              airwindows
            ]}

            # Make reapack available.
            mkdir -p ~/.config/REAPER/UserPlugins
            ln -sf ${reaper-reapack-extension}/UserPlugins/* ~/.config/REAPER/UserPlugins/

            bash ~/scripts/check-vulkan-deps.sh

            winetricks dxvk

            ${ensureYabridgePaths [
              "$HOME/win-plugins"
              "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
            ]}

            yabridgectl sync --prune
            yabridgectl status

            bash ~/win-plugins/setup-paths.sh
          '';
        };
      };
    };
}
