{
  description = "ide";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            # For chow-tape-model.
            "libsoup-2.74.3"
          ];
        };
      };

      diff-highlight = pkgs.linkFarm "diff-highlight" [
        {
          name = "bin/diff-highlight";
          path = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
        }
      ];

      basePkgs = with pkgs; [
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

      goPkgs = with pkgs; [
        go_1_24
        gopls
        revive
        gocc
      ];

      luaPkgs = with pkgs; [
        lua-language-server
        luajitPackages.luacheck
        stylua
      ];

      rustPkgs = with pkgs; [
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

      phpPkgs = with pkgs; [
        php84
        phpactor
        php84Extensions.sqlite3
        php84Packages.composer
        php84Packages.phpstan
        pint
      ];

      pythonPkgs = with pkgs; [
        pipx
        pipenv
        black
        pylint
      ];

      webdevPkgs = with pkgs; [
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

      devPkgs = with pkgs; [
        basePkgs

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
        asciinema
        go-jsonnet

        goPkgs
        luaPkgs
        rustPkgs
        phpPkgs
        pythonPkgs
        webdevPkgs
      ];

      spirv-tools-lib = pkgs.linkFarm "spirv-tools-lib" [
        {
          name = "lib/libSPIRV-Tools.so";
          path = "${pkgs.spirv-tools}/lib/libSPIRV-Tools-shared.so";
        }
      ];

      reaper-default-5-dark-extended-theme = pkgs.stdenv.mkDerivation {
        name = "reaper-default-5-dark-extended-theme";
        src = pkgs.fetchurl {
          url = "https://stash.reaper.fm/30492/Default_5_Dark_Extended.ReaperThemeZip";
          sha256 = "9fd0577863dc267e093dacca0a7ddafd6a03a224a9224a8393ff82b67ab6727d";
        };
        phases = [ "installPhase" ];
        installPhase = ''
          install -m644 -D $src $out/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip
        '';
      };

      levelrider = pkgs.stdenv.mkDerivation {
        name = "levelrider";
        src = pkgs.fetchFromGitHub {
          owner = "unicornsasfuel";
          repo = "levelrider";
          rev = "ef54128";
          sha256 = "sha256-vyoqoA75hQ7SbliPCVs8ZTmDS3GHPGId4hF/9c34lB8=";
        };

        buildInputs = [
          pkgs.which
          pkgs.faust2lv2
        ];

        dontWrapQtApps = true;

        buildPhase = ''
          faust2lv2 -vec -time -t 99999 levelrider.dsp
        '';

        installPhase = ''
          mkdir -p $out/lib/lv2
          cp -r levelrider.lv2/ $out/lib/lv2
        '';
      };

      audioPkgs = with pkgs; [
        # Pipewire JACK management.
        pipewire.jack

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

        # Raysession and Reaper.
        raysession
        python313Packages.legacy-cgi
        reaper
        reaper-reapack-extension
        reaper-default-5-dark-extended-theme

        # Wine and yabridge.
        yabridge
        yabridgectl
        winetricks
        cabextract

        # General programs.
        fluidsynth
        rakarrack

      ];

      clapPlugins = with pkgs; [
        zam-plugins
        lsp-plugins
        chow-tape-model
        airwin2rack
      ];

      lv2Plugins = with pkgs; [
        guitarix
        gxplugins-lv2
        x42-plugins
        x42-avldrums
        infamousPlugins
        distrho-ports
        mda_lv2
        swh_lv2
        mod-distortion
        kapitonov-plugins-pack
        stone-phaser
        magnetophonDSP.VoiceOfFaust
        magnetophonDSP.MBdistortion
        levelrider
      ];

      docker_user = "ide";
      docker_group = "ide";
      docker_uid = "1000";
      docker_gid = "1000";

      makePluginPath =
        type: paths:
        builtins.concatStringsSep ";" (
          map (path: path + "/lib/${type}") (builtins.filter (x: x != null) paths)
        );

      setIni =
        file: section: attrs:
        builtins.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (name: value: ''
            ${pkgs.crudini}/bin/crudini --set --ini-options=nospace ${file} ${section} ${name} "${value}"
          '') attrs
        );
    in
    {
      docker = pkgs.dockerTools.streamLayeredImage {
        name = "ghcr.io/mgnsk/ide";
        tag = "edge";
        contents = devPkgs;
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
        # Dummy shell definition for showing diff for all packages
        # when using the nix-flake-update.sh script.
        all = pkgs.mkShellNoCC {
          buildInputs = [
            devPkgs
            audioPkgs
            clapPlugins
            lv2Plugins
          ];
        };

        dev = pkgs.mkShellNoCC {
          buildInputs = devPkgs;
          shellHook = ''
            export CUSTOM_HOST="ide-dev"
            export SHELL="${pkgs.bash}/bin/bash"
          '';
        };

        audio = pkgs.mkShellNoCC {
          buildInputs = [
            basePkgs
            audioPkgs
            clapPlugins
            lv2Plugins
          ];
          shellHook = ''
            set -e

            function cleanup {
              echo "Exiting audio shell"
              wineserver -k || true
            }

            trap cleanup EXIT

            export CUSTOM_HOST="ide-audio"
            export SHELL="${pkgs.bash}/bin/bash"
            export NIX_PROFILES="${pkgs.yabridge} $NIX_PROFILES"
            export WINEFSYNC=1
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath audioPkgs}:$LD_LIBRARY_PATH"

            # Setup reaper.
            mkdir -p ~/.config/REAPER/UserPlugins
            ln -sf ${pkgs.reaper-reapack-extension}/UserPlugins/* ~/.config/REAPER/UserPlugins/

            ${setIni "~/.config/REAPER/reaper.ini" "reaper" {
              lastthemefn5 = "${reaper-default-5-dark-extended-theme}/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip";
              clap_path_linux-x86_64 = "~/.clap;${makePluginPath "clap" clapPlugins}";
              lv2path_linux = "~/.lv2;${makePluginPath "lv2" lv2Plugins}";
              vstpath = "~/.vst;~/.vst3";
              ui_scale = "1.0";
            }}

            bash ~/scripts/check-vulkan-deps.sh

            # Needed for some Windows VST plugins.
            winetricks -q dxvk

            # Needed for Guitar Pro 5.
            winetricks -q gdiplus

            bash ~/win-plugins/setup-paths.sh

            set +e

            echo "Starting audio shell"
          '';
        };
      };
    };
}
