{
  description = "ide";

  inputs = {
    nixpkgs-audio.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-dev.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Neovim plugins not in nixpkgs.
    nvim-plugin-tree-sitter-manager = {
      url = "github:romus204/tree-sitter-manager.nvim";
      flake = false;
    };
    nvim-plugin-autotabline = {
      url = "github:mgnsk/autotabline.nvim";
      flake = false;
    };
    nvim-plugin-dumb-autopairs = {
      url = "github:mgnsk/dumb-autopairs.nvim";
      flake = false;
    };
    nvim-plugin-nvim-fundo = {
      url = "github:kevinhwang91/nvim-fundo";
      flake = false;
    };
    nvim-plugin-vim-eel = {
      url = "github:NlGHT/vim-eel";
      flake = false;
    };
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

      myvscode = devpkgs.vscode-with-extensions.override {
        vscodeExtensions = with devpkgs.vscode-extensions; [
          anthropic.claude-code
          #bufbuild.vscode-buf
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          golang.go
          hashicorp.hcl
          ms-python.black-formatter
          ms-python.isort
          ms-python.python
          redhat.vscode-yaml
          streetsidesoftware.code-spell-checker
          sumneko.lua
          tamasfe.even-better-toml
          tim-koehler.helm-intellisense
        ];
      };

      nvimPlugins =
        (with inputs; [
          nvim-plugin-autotabline
          nvim-plugin-dumb-autopairs
          nvim-plugin-nvim-fundo
          nvim-plugin-vim-eel
        ])
        ++ (with devpkgs.vimPlugins; [
          blink-cmp
          conform-nvim
          fzf-lua
          gitsigns-nvim
          luvit-meta
          nvim-ansible
          nvim-colorizer-lua
          nvim-lint
          oil-nvim
          promise-async
          vim-fugitive
          vim-jsonpath
          vim-wordmotion
          vscode-nvim
        ])
        ++ (with devpkgs.vimPlugins.nvim-treesitter-parsers; [
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
          rust
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

      nvimPluginsPack = devpkgs.stdenv.mkDerivation {
        name = "mgnsk-neovim-plugins";
        buildCommand = ''
          mkdir -p $out/pack/plugins/start/
          ${devpkgs.lib.concatMapStringsSep "\n" (path: "ln -s ${path} $out/pack/plugins/start/") nvimPlugins}
        '';
      };

      myneovim = devpkgs.neovim.override {
        wrapperArgs = [
          "--add-flags"
          # Contains the queries/ dir.
          ''--cmd "set rtp^=${inputs.nvim-plugin-tree-sitter-manager}/runtime"''

          # Add the plugin pack to packpath.
          "--add-flags"
          ''--cmd "set packpath^=${nvimPluginsPack.outPath}"''
        ];
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
        cuetools
        curl
        diff-highlight
        direnv
        fd
        fdupes
        file
        findutils
        flatpak-xdg-utils
        fzf
        gawk
        gcc
        gh
        gh-tpl
        git
        github-copilot-cli
        glances
        glibcLocalesUtf8
        glow
        gnugrep
        gnused
        go-jsonnet
        gojq
        hadolint
        helm-ls
        iotop
        jq
        jsonnet-language-server
        just
        less
        libxml2
        man
        moreutils
        ncurses
        qrcp
        ripgrep
        shfmt
        shntool
        tmux
        tree
        tusk-go
        unzip
        vivid
        wget
        which
        xdg-dbus-proxy
        yt-dlp

        # Bash.
        bash-language-server
        shellcheck
        shfmt

        # Go.
        go
        gopls
        revive

        # Rust.
        cargo
        clippy
        rust-analyzer
        rustc
        rustfmt

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
        eslint
        html-tidy
        markdownlint-cli
        nodejs_25
        npm-check-updates
        pnpm
        prettier
        stylelint
        typescript-go
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

        # VSCode.
        myvscode

        # Neovim.
        myneovim
      ];

      spirv-tools-lib = audiopkgs.linkFarm "spirv-tools-lib" [
        {
          name = "lib/libSPIRV-Tools.so";
          path = "${audiopkgs.spirv-tools}/lib/libSPIRV-Tools-shared.so";
        }
      ];

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
        raysession

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
            devPkgs
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
            cp ~/Shared/Default_5_Dark_Extended.ReaperThemeZip ~/.config/REAPER/ColorThemes/
            ${setIni "~/.config/REAPER/reaper.ini" "reaper" {
              lastthemefn5 = "~/.config/REAPER/ColorThemes/Default_5_Dark_Extended.ReaperThemeZip";
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
