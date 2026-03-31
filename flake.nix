{
  description = "ide";

  inputs = {
    nixpkgs-audio.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-dev.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";

      audiopkgs = import inputs.nixpkgs-audio {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      devpkgs = import inputs.nixpkgs-dev {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      gh-tpl = devpkgs.stdenv.mkDerivation rec {
        name = "gh-tpl";
        version = "0.0.9";
        src = devpkgs.fetchurl {
          url = "https://github.com/mgnsk/gh-tpl/releases/download/v${version}/gh-tpl-v${version}-linux-amd64.tar.gz";
          sha256 = "1970b39372d421e831098529d71c126014f3d33225fffcdfc03a993aa90a05f4";
        };
        sourceRoot = ".";
        installPhase = ''
          install -m755 -D gh-tpl $out/bin/gh-tpl
        '';
      };

      tusk-go = devpkgs.stdenv.mkDerivation rec {
        name = "tusk-go";
        version = "0.8.1";
        src = devpkgs.fetchurl {
          url = "https://github.com/rliebz/tusk/releases/download/v${version}/tusk_${version}_linux_amd64.tar.gz";
          sha256 = "3be7a872673c674dbcffbf4cfac2580152edf6d1f072d9be491fb69d2a460761";
        };
        sourceRoot = ".";
        installPhase = ''
          install -m755 -D tusk $out/bin/tusk
        '';
      };

      diff-highlight = devpkgs.linkFarm "diff-highlight" [
        {
          name = "bin/diff-highlight";
          path = "${devpkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
        }
      ];

      pint = devpkgs.stdenv.mkDerivation rec {
        name = "pint";
        version = "1.29.0";
        src = devpkgs.fetchurl {
          url = "https://github.com/laravel/pint/releases/download/v${version}/pint.phar";
          sha256 = "e29e7a16384c5baacf644d53402e963b320c9ec5c8b4afd20c30cccf9add1c7b";
        };
        phases = [ "installPhase" ]; # Removes all phases except installPhase (no unpackPhase).
        installPhase = ''
          install -m755 -D $src $out/bin/pint
        '';
      };

      devPkgs = with devpkgs; [
        # General.
        asciinema
        bash
        bash-completion
        bat
        buf
        caddy
        claude-code
        coreutils
        cspell
        git
        diff-highlight
        direnv
        fd
        file
        findutils
        fzf
        gawk
        gcc
        gh
        gh-tpl
        git
        github-copilot-cli
        glibcLocalesUtf8
        glow
        gnugrep
        gnused
        gojq
        go-jsonnet
        hadolint
        helm-ls
        jsonnet-language-server
        just
        less
        libxml2
        man
        moreutils
        ncurses
        neovim
        qrcp
        ripgrep
        shfmt
        shntool
        tmux
        tree
        tree-sitter
        tusk-go
        unzip
        vivid
        wget
        which

        # Bash.
        shfmt
        bash-language-server
        shellcheck

        # Go.
        go
        gopls
        revive

        # Rust.
        rustc
        rustfmt
        clippy
        rust-analyzer
        cargo

        # Lua.
        lua-language-server
        lua54Packages.luacheck
        stylua

        # PHP.
        php85
        php85Packages.composer
        phpactor
        phpstan
        pint

        # Python.
        black
        pylint
        ty
        uv

        # Web.
        html-tidy
        nodejs_25
        npm-check-updates
        pnpm
        eslint
        prettier
        stylelint
        typescript-go
        markdownlint-cli
        vscode-langservers-extracted
        yaml-language-server
        yamllint

        # Ansible.
        ansible
        ansible-language-server
        ansible-lint

        # Nix.
        nil
        nixfmt
      ];

      spirv-tools-lib = audiopkgs.linkFarm "spirv-tools-lib" [
        {
          name = "lib/libSPIRV-Tools.so";
          path = "${audiopkgs.spirv-tools}/lib/libSPIRV-Tools-shared.so";
        }
      ];

      reaper-default-5-dark-extended-theme = audiopkgs.stdenv.mkDerivation {
        name = "reaper-default-5-dark-extended-theme";
        src = audiopkgs.fetchurl {
          url = "https://stash.reaper.fm/30492/Default_5_Dark_Extended.ReaperThemeZip";
          sha256 = "9fd0577863dc267e093dacca0a7ddafd6a03a224a9224a8393ff82b67ab6727d";
        };
        phases = [ "installPhase" ];
        installPhase = ''
          install -m644 -D $src $out/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip
        '';
      };

      levelrider = audiopkgs.stdenv.mkDerivation {
        name = "levelrider";
        src = audiopkgs.fetchFromGitHub {
          owner = "unicornsasfuel";
          repo = "levelrider";
          rev = "ef54128";
          sha256 = "sha256-vyoqoA75hQ7SbliPCVs8ZTmDS3GHPGId4hF/9c34lB8=";
        };

        buildInputs = [
          audiopkgs.which
          audiopkgs.faust2lv2
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

      audioPkgs = with audiopkgs; [
        # For LSP and Zam plugins.
        mesa
        libGL

        # Complete Vulkan setup to fix Vulkan plugins.
        libdrm
        llvmPackages_21.libllvm
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
        stdenv.cc.cc.lib
        libdisplay-info

        # Reaper.
        pipewire.jack
        reaper
        reaper-reapack-extension
        reaper-default-5-dark-extended-theme

        # Wine and yabridge.
        yabridge
        yabridgectl
        wineWowPackages.yabridge
        winetricks

        # General programs.
        fluidsynth
      ];

      clapPlugins = with audiopkgs; [
        airwin2rack
        surge-XT
      ];

      lv2Plugins = with audiopkgs; [
        x42-plugins
        x42-avldrums
        magnetophonDSP.VoiceOfFaust
        magnetophonDSP.MBdistortion
        levelrider
        neural-amp-modeler-lv2
      ];

      vst3Plugins = with audiopkgs; [
        chow-phaser
      ];

      makePluginPath =
        type: paths:
        builtins.concatStringsSep ";" (
          map (path: path + "/lib/${type}") (builtins.filter (x: x != null) paths)
        );

      setIni =
        file: section: attrs:
        builtins.concatStringsSep "\n" (
          audiopkgs.lib.mapAttrsToList (name: value: ''
            ${audiopkgs.crudini}/bin/crudini --set --ini-options=nospace ${file} ${section} ${name} "${value}"
          '') attrs
        );
    in
    {
      devShells.${system} = {
        dev = devpkgs.mkShellNoCC rec {
          buildInputs = devPkgs;
          shellHook = ''
            export CUSTOM_HOST="ide-dev"

            # Source bash-completion.
            if [ -f "${devpkgs.bash-completion}/share/bash-completion/bash_completion" ]; then
              source "${devpkgs.bash-completion}/share/bash-completion/bash_completion"
            fi

            # Source any per-package completions from buildInputs.
            for dir in ${toString (map (p: "${p}/share/bash-completion/completions") buildInputs)}; do
              if [ -d "$dir" ]; then
                for f in "$dir"/*; do
                  source "$f" 2>/dev/null || true
                done
              fi
            done
          '';
        };

        audio = audiopkgs.mkShellNoCC {
          buildInputs = [
            audioPkgs
            clapPlugins
            lv2Plugins
            vst3Plugins
          ];
          shellHook = ''
            set -e
            function cleanup {
              echo "Exiting audio shell"
              wineserver -k || true
            }

            trap cleanup EXIT

            export WINEPREFIX="$HOME/.wine-audio"
            export LD_LIBRARY_PATH="${audiopkgs.lib.makeLibraryPath audioPkgs}:$LD_LIBRARY_PATH"
            export NIX_PROFILES="${audiopkgs.yabridge} $NIX_PROFILES"
            export CUSTOM_HOST="ide-audio"

            mkdir -p ~/.config/REAPER
            ${setIni "~/.config/REAPER/reaper.ini" "reaper" {
              lastthemefn5 = "${reaper-default-5-dark-extended-theme}/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip";
              clap_path_linux-x86_64 = "~/.clap;${makePluginPath "clap" clapPlugins}";
              lv2path_linux = "~/.lv2;${makePluginPath "lv2" lv2Plugins}";
              vstpath = "~/.vst;~/.vst3;${makePluginPath "vst3" vst3Plugins}";
              ui_scale = "1.0";
            }}

            echo "Starting audio shell"
            bash ~/.scripts/ide-audio.sh

            set +e
          '';
        };
      };
    };
}
