{
  description = "ide";

  inputs = {
    nixpkgs-audio.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-home.url = "github:nixos/nixpkgs?ref=nixos-unstable";

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

    nvim-plugins-tree-sitter-balafon = {
      url = "github:mgnsk/tree-sitter-balafon";
      inputs.nixpkgs.follows = "nixpkgs-home";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-home";
    };

    # Firefox extension packages (vimium, ublock-origin, ...).
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";
      username = builtins.getEnv "USER";

      audiopkgs = import inputs.nixpkgs-audio {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      homepkgs = import inputs.nixpkgs-home {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      mozillaAddons = import inputs.firefox-addons { pkgs = homepkgs; };
      firefoxAddons = mozillaAddons.firefox-addons;

      # Not packaged in nur-expressions' thunderbird-addons set, so built
      # directly from the upstream .xpi the same way that set's entries are.
      dkimVerifierExtension =
        mozillaAddons.lib.mozilla.mkBuildMozillaXpiAddon
          {
            inherit (homepkgs) fetchurl stdenv;
          }
          {
            pname = "dkim-verifier";
            version = "6.3.0";
            addonId = "dkim_verifier@pl";
            url = "https://github.com/lieser/dkim_verifier/releases/download/v6.3.0/dkim_verifier-6.3.0.xpi";
            sha256 = "5ae95b4d560257b2e5722e1d3824a4031fb74d5d57b790dfc12f76a11dc1501a";
            meta = with homepkgs.lib; {
              homepage = "https://github.com/lieser/dkim_verifier";
              description = "Validates the DKIM/ARC signature of incoming e-mails and shows the result in the message header";
              license = licenses.mpl20;
              platforms = platforms.all;
            };
          };

      # Brave Origin is Chromium-based, so home-manager's programs.brave-origin
      # (modules/programs/chromium.nix) has no `policies`/`extraOpts` option
      # like programs.firefox does - Chromium only reads enterprise policies
      # from /etc, which is outside what a standalone (non-NixOS) home-manager
      # profile can write directly. Generate the policy file here and install
      # it via a sudo activation script instead (see home.activation below).
      bravePolicyFile = homepkgs.writeText "brave-policy.json" (
        builtins.toJSON {
          # Matches Firefox: disallow going through Google/Brave account
          # sign-in.
          BrowserSignin = 0;
          # Don't ask where to save every download.
          PromptForDownloadLocation = false;
          # Shields set to block ads/trackers (was already the case, now locked).
          BraveShieldsEnabled = true;
          BraveShieldsDefaultAdsSetting = "block";
          BraveShieldsDefaultTrackersSetting = "block";

          # Use 1Password instead of Brave's built-in password/card manager,
          # matching the Firefox profile.
          PasswordManagerEnabled = false;
          AutofillCreditCardEnabled = false;
          AutofillAddressEnabled = false;

          # Reopen previous windows and tabs on startup, matching Firefox.
          RestoreOnStartup = 1;

          # Not signed in / no Brave sync in use.
          SyncDisabled = true;

          # brave-origin already strips Brave's own updater; also disable the
          # Chromium component updater (Widevine, Safe Browsing lists, etc.)
          # so Nix stays the sole source of updates.
          ComponentUpdatesEnabled = false;

          # Preferred language order (intl.accept_languages).
          ForcedLanguages = [
            "et"
            "en-US"
            "en"
          ];

          # Translate was disabled for both languages actually browsed in.
          TranslateEnabled = true;

          SafeBrowsingExtendedReportingEnabled = false;
          SpellcheckLanguage = [ "en-US" ];
        }
      );

      # Computed once at build time instead of shelling out to vivid on every shell startup.
      lsColors = homepkgs.lib.removeSuffix "\n" (
        builtins.readFile "${homepkgs.runCommand "ls-colors-ayu" { }
          "${homepkgs.vivid}/bin/vivid generate ayu > $out"
        }"
      );

      gh-tpl = homepkgs.stdenv.mkDerivation rec {
        name = "gh-tpl";
        version = "0.0.9";
        src = homepkgs.fetchurl {
          url = "https://github.com/mgnsk/gh-tpl/releases/download/v${version}/gh-tpl-v${version}-linux-amd64.tar.gz";
          sha256 = "1970b39372d421e831098529d71c126014f3d33225fffcdfc03a993aa90a05f4";
        };
        sourceRoot = ".";
        installPhase = ''
          install -m755 -D gh-tpl $out/bin/gh-tpl
        '';
      };

      tusk-go = homepkgs.stdenv.mkDerivation rec {
        name = "tusk-go";
        version = "0.8.1";
        src = homepkgs.fetchurl {
          url = "https://github.com/rliebz/tusk/releases/download/v${version}/tusk_${version}_linux_amd64.tar.gz";
          sha256 = "3be7a872673c674dbcffbf4cfac2580152edf6d1f072d9be491fb69d2a460761";
        };
        sourceRoot = ".";
        installPhase = ''
          install -m755 -D tusk $out/bin/tusk
        '';
      };

      diff-highlight = homepkgs.linkFarm "diff-highlight" [
        {
          name = "bin/diff-highlight";
          path = "${homepkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
        }
      ];

      pint = homepkgs.stdenv.mkDerivation rec {
        name = "pint";
        version = "1.29.0";
        src = homepkgs.fetchurl {
          url = "https://github.com/laravel/pint/releases/download/v${version}/pint.phar";
          sha256 = "e29e7a16384c5baacf644d53402e963b320c9ec5c8b4afd20c30cccf9add1c7b";
        };
        phases = [ "installPhase" ]; # Removes all phases except installPhase (no unpackPhase).
        installPhase = ''
          install -m755 -D $src $out/bin/pint
        '';
      };

      nvimPlugins =
        (with inputs; [
          nvim-plugin-autotabline
          nvim-plugin-dumb-autopairs
          nvim-plugin-nvim-fundo
          nvim-plugins-tree-sitter-balafon.packages.x86_64-linux.nvimParser
        ])
        ++ (with homepkgs.vimPlugins; [
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
        ++ (with homepkgs.vimPlugins.nvim-treesitter-parsers; [
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

      nvimPluginsPack = homepkgs.stdenv.mkDerivation {
        name = "mgnsk-neovim-plugins";
        buildCommand = ''
          mkdir -p $out/pack/plugins/start/
          ${homepkgs.lib.concatMapStringsSep "\n" (
            path: "ln -s ${path} $out/pack/plugins/start/"
          ) nvimPlugins}
        '';
      };

      myneovim = homepkgs.neovim.override {
        wrapperArgs = [
          "--add-flags"
          # Contains the queries/ dir.
          ''--cmd "set rtp^=${inputs.nvim-plugin-tree-sitter-manager}/runtime"''

          # Add the plugin pack to packpath.
          "--add-flags"
          ''--cmd "set packpath^=${nvimPluginsPack.outPath}"''
        ];
      };

      homePkgs = with homepkgs; [
        # General.
        asciinema
        bash
        bash-completion
        bat
        buf
        caddy
        coreutils
        cspell
        cuetools
        curl
        diff-highlight
        fd
        fdupes
        file
        findutils
        fuse
        gawk
        gcc
        gh
        gh-tpl
        git
        glibcLocalesUtf8
        glow
        gnugrep
        gnused
        go-jsonnet
        go-task
        gojq
        hadolint
        helm-ls
        inotify-tools
        jq
        jsonnet-language-server
        just
        less
        libxml2
        man
        moreutils
        ncurses
        patchelf
        qrcp
        qrencode
        rclone
        ripgrep
        rsync
        shfmt
        shntool
        tree
        tree-sitter
        tusk-go
        unzip
        vim
        vivid
        wget
        which

        # Desktop and file management.
        arandr
        ark
        baobab
        geany
        glances
        gnome-disk-utility
        grim
        gthumb
        iotop
        kdePackages.ffmpegthumbs
        kdePackages.kde-cli-tools
        kdePackages.kdegraphics-thumbnailers
        kdePackages.kimageformats
        libnotify
        libreoffice
        hunspellDicts.et-ee
        pavucontrol
        picom
        powertop
        qdigidoc
        qt6Packages.qt6ct
        qt6Packages.qtimageformats
        slurp
        tint2
        unrar
        wdisplays
        web-eid-app
        webp-pixbuf-loader
        wl-clipboard
        zenity

        # Multimedia.
        gimp
        handbrake
        inkscape
        picard
        smplayer
        vmpk
        whipper
        yt-dlp

        # AI.
        antigravity-cli
        mcp-nixos

        # Bash.
        bash-language-server
        shellcheck
        shfmt

        # Git.
        commitmsgfmt

        # Go.
        go
        gopls
        revive
        ginkgo

        # Lua.
        lua-language-server
        luajitPackages.luacheck
        stylua

        # PHP.
        php
        phpPackages.composer
        phpactor
        phpstan
        pint

        # Python.
        black
        pylint
        (python3.withPackages (
          ps: with ps; [
            dbus-next
            pytest
          ]
        ))
        ty
        uv

        # Web.
        biome
        markdownlint-cli
        nodejs
        npm-check-updates
        pnpm
        prettier
        typescript-go
        yaml-language-server
        yamllint

        # Ansible.
        ansible
        ansible-language-server
        ansible-lint

        # Nix.
        nil
        nixfmt

        # Neovim.
        myneovim

        # Fonts. otf-font-awesome moved from pacman here so nix-built GTK
        # apps (waybar) can find it through their own fontconfig. Noto Sans
        # is needed too: "Roboto, Helvetica, Arial" in the waybar style are
        # not installed anywhere, so Pango skipped straight past them to
        # Font Awesome (which covers plain ASCII) for regular bar text.
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-lgc-plus

        # Sway companions (sway itself comes from wayland.windowManager.sway.enable).
        swayidle
        swaynotificationcenter
        j4-dmenu-desktop
        wmenu
        gammastep
        wayvnc
        kdePackages.dolphin
        networkmanagerapplet
        blueman
        xwayland
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];

      spirv-tools-lib = audiopkgs.linkFarm "spirv-tools-lib" [
        {
          name = "lib/libSPIRV-Tools.so";
          path = "${audiopkgs.spirv-tools.lib}/lib/libSPIRV-Tools-shared.so";
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
        llvmPackages_22.libllvm
        elfutils
        zstd
        libxcb
        wayland
        libz
        libx11
        libxshmfence
        libxcb-keysyms
        libudev-zero
        expat
        spirv-tools-lib
        stdenv.cc.cc.lib
        libdisplay-info

        reaper
        reaper-reapack-extension
        qjackctl
        fluidsynth
      ];

      winePkgs = with audiopkgs; [
        # Wine and yabridge.
        yabridge
        yabridgectl
        wineWow64Packages.yabridge
        winetricks
      ];

      clapPlugins = with audiopkgs; [
        airwin2rack
        surge-xt
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

      # Roots for closurePositions below. Derived from the actual build
      # outputs (home-manager's merged package list, the audio devShell's
      # buildInputs) rather than a hand-curated list, so newly added
      # programs/packages are automatically included without maintenance.
      packageSets = {
        nixpkgs-home = self.homeConfigurations.${username}.config.home.packages;
        nixpkgs-audio = self.devShells.${system}.audio.buildInputs;
      };

      # For each package set, the meta.position of every package plus its
      # full transitive build closure, deduplicated by drvPath. Used by
      # nix/flake-update.sh to show per-file diffs scoped to declared
      # packages instead of a whole-nixpkgs-tree diff.
      closurePositions = builtins.mapAttrs (
        _: pkgs:
        let
          startSet = builtins.filter (p: builtins.isAttrs p && p ? drvPath) (homepkgs.lib.flatten pkgs);
          closure = builtins.genericClosure {
            startSet = map (p: {
              key = p.drvPath;
              val = p;
            }) startSet;
            operator =
              { val, ... }:
              map
                (d: {
                  key = d.drvPath;
                  val = d;
                })
                (
                  builtins.filter (d: builtins.isAttrs d && d ? drvPath) (
                    homepkgs.lib.flatten (
                      (val.buildInputs or [ ])
                      ++ (val.nativeBuildInputs or [ ])
                      ++ (val.propagatedBuildInputs or [ ])
                      ++ (val.propagatedNativeBuildInputs or [ ])
                    )
                  )
                );
          };
        in
        homepkgs.lib.unique (
          builtins.filter (x: x != null) (map ({ val, ... }: val.meta.position or null) closure)
        )
      ) packageSets;
    in
    {
      devShells.${system} = {
        audio = audiopkgs.mkShellNoCC {
          buildInputs = [
            audioPkgs
            winePkgs
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
            export LD_LIBRARY_PATH="${audiopkgs.lib.makeLibraryPath winePkgs}:$LD_LIBRARY_PATH"
            export LD_LIBRARY_PATH="${audiopkgs.lib.makeLibraryPath audioPkgs}:$LD_LIBRARY_PATH"
            export NIX_PROFILES="${audiopkgs.yabridge} $NIX_PROFILES"
            export CUSTOM_HOST="ide-audio"

            mkdir -p ~/.config/REAPER/ColorThemes
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

            source ~/.bashrc
          '';
        };
      };

      inherit packageSets closurePositions;

      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = homepkgs;
        modules = [
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            home.stateVersion = "24.05";
            home.packages = homePkgs;

            home.sessionPath = [
              "$HOME/.local/bin"
              "$HOME/go/bin"
              "/usr/share/git/diff-highlight"
              "$HOME/.scripts/bin"
            ];

            home.sessionVariables = {
              THEME = "light";
              GLAMOUR_STYLE = "light";
              GLOW_STYLE = "light";

              EDITOR = "nvim";
              VISUAL = "nvim";
              PAGER = "less -R";
              MANPAGER = "less -R";
              LESS = "-R --mouse --wheel-lines=3";

              GIT_LOG_PRETTY_FORMAT = "%C(yellow)%h%Creset%x1f%ct%x1f%Creset%s%C(cyan)%d%x1f%Cblue<%an>";

              LS_COLORS = lsColors;

              SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

              LIBRARY_PATH = "$HOME/.local/lib";

              ANSIBLE_NOCOWS = "1";

              NODE_OPTIONS = "--max_old_space_size=4096";

              HISTTIMEFORMAT = "[%F %T] ";
            };

            programs.home-manager.enable = true;

            # Nix-built GUI programs (alacritty, kitty, ...) link against
            # glvnd, which on NixOS finds GPU drivers via /run/opengl-driver.
            # That path doesn't exist on Arch, so EGL/GLX finds zero vendor
            # ICDs and every OpenGL window fails to open. This symlinks the
            # Mesa drivers from this flake's nixpkgs into /run/opengl-driver
            # (one-time `sudo .../non-nixos-gpu-setup` after switching).
            targets.genericLinux.enable = true;

            programs.bash = {
              enable = true;
              enableCompletion = true;

              historyFile = "/home/${username}/.local/state/.bash_history";
              historyFileSize = -1;
              historySize = -1;
              shellOptions = [ "histappend" ];

              shellAliases = {
                ls = "/bin/ls -hv --group-directories-first --color=auto";
                l = "/bin/ls -Alhv --group-directories-first --color=auto";
                ltr = "/bin/ls -hvlatr --group-directories-first --color=auto";
                ".." = "cd ..";
                grep = "/bin/grep --color=auto";
                qr = "/bin/qrencode -t ANSI256";
              };

              initExtra = ''
                mkdir -p "$HOME/.local/state"

                PROMPT_COMMAND=__prompt_command

                __prompt_command() {
                	local EXIT="$?"
                	PS1=""

                	history -a

                	local RCol='\[\e[0m\]'
                	local Red='\[\e[0;31m\]'
                	local Gre='\[\e[0;32m\]'
                	local BrBlu='\[\e[0;36m\]'

                	local userHostColor="''${USERHOST_COLOR:-$BrBlu}"
                	local customHost="''${CUSTOM_HOST:-\h}"

                	PS1+="''${RCol}[\t] ''${userHostColor}\u@''${customHost} ''${Gre}\w"

                	if [ $EXIT != 0 ]; then
                		PS1+=" ''${Red}[''${EXIT}]"
                	fi

                	PS1+=" ''${RCol}\n> "
                }
              '';

              profileExtra = ''
                pre() {
                	if command -v gsettings &>/dev/null; then
                		gsettings set "org.gnome.desktop.interface" \
                			gtk-theme 'Adwaita Sans'

                		gsettings set "org.gnome.desktop.interface" \
                			icon-theme 'Adwaita Sans'

                		gsettings set "org.gnome.desktop.interface" \
                			font-name 'Adwaita Sans'

                		gsettings set "org.gnome.desktop.interface" \
                			monospace-font-name 'Monospace 11'

                		gsettings set "org.gnome.desktop.interface" \
                			document-font-name 'Adwaita Sans 11'

                		gsettings set "org.gnome.desktop.interface" \
                			font-antialiasing 'grayscale'

                		gsettings set "org.gnome.desktop.interface" \
                			font-hinting 'slight'

                		gsettings set "org.gnome.desktop.interface" \
                			text-scaling-factor "1.2"
                	fi

                	if command -v kbuildsycoca6 &>/dev/null; then
                		XDG_MENU_PREFIX=arch- /usr/bin/kbuildsycoca6 --noincremental &>/dev/null
                	fi
                }

                # TTY1: start sway at login if available.
                if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a "$XDG_VTNR" = 1; then
                	if command -v sway &>/dev/null; then
                		export XDG_CURRENT_DESKTOP=sway
                		pre
                		exec sway --config ~/.config/sway/config-main
                	fi
                fi

                # TTY2: start openbox at login if available.
                if test -z "$DISPLAY" -a "$XDG_VTNR" = 2; then
                	if command -v openbox-session &>/dev/null; then
                		export XDG_CURRENT_DESKTOP=openbox
                		pre
                		exec startx
                	fi
                fi
              '';
            };

            programs.alacritty = {
              enable = true;
              settings = {
                font.size = 12;
                font.normal.family = "monospace";

                colors = {
                  primary = {
                    background = "#FFFFFF";
                    foreground = "#000000";
                  };
                  selection = {
                    text = "#000000";
                    background = "#d7ba7d";
                  };
                  cursor.cursor = "#cccccc";
                  normal = {
                    black = "#000000";
                    red = "#c72e0f";
                    green = "#008000";
                    yellow = "#795e25";
                    blue = "#007acc";
                    magenta = "#af00db";
                    cyan = "#56b6c2";
                    white = "#000000";
                  };
                  bright.black = "#808080";
                };
              };
            };

            programs.foot = {
              enable = true;
              settings = {
                main = {
                  pad = "2x1";
                  font = "monospace:size=12";
                };

                # Non-solarized colors, see:
                # https://codeberg.org/dnkl/foot/commit/3cf11bfea9e4787998c538bd312c456fd8287fd1
                "colors-dark" = {
                  alpha = 1.0;
                  background = "ffffff";
                  foreground = "000000";

                  selection-foreground = "000000";
                  selection-background = "d7ba7d";

                  cursor = "ffffff cccccc";

                  regular0 = "000000";
                  regular1 = "c72e0f";
                  regular2 = "008000";
                  regular3 = "795e25";
                  regular4 = "007acc";
                  regular5 = "af00db";
                  regular6 = "56b6c2";
                  regular7 = "000000";

                  bright0 = "808080";
                };
              };
            };

            programs.kitty = {
              enable = true;

              settings = {
                text_composition_strategy = "legacy";
                shell_integration = "no-cursor";
                enable_audio_bell = false;
                enabled_layouts = "splits";

                tab_bar_style = "custom";
                tab_bar_align = "left";
                tab_activity_symbol = "!-";
                bell_on_tab = "!-";
                tab_title_template = "{index}:{tab.active_exe}{bell_symbol or activity_symbol}";
                active_tab_title_template = "{index}:{tab.active_exe}{bell_symbol or activity_symbol or '*'}";
                active_tab_font_style = "bold";

                font_family = "monospace";
                font_size = 12;
              };

              keybindings = {
                "ctrl+equal" = "change_font_size all +1.0";
                "ctrl+plus" = "change_font_size all +1.0";
                "ctrl+kp_add" = "change_font_size all +1.0";
                "ctrl+minus" = "change_font_size all -1.0";
                "ctrl+kp_subtract" = "change_font_size all -1.0";

                # Tmux-like mapping for tabs and windows.
                "ctrl+b>c" = "new_tab_with_cwd";
                "ctrl+b>n" = "kitten tab_nav.py next";
                "ctrl+b>p" = "kitten tab_nav.py prev";

                "ctrl+b>\"" = "launch --location=hsplit --cwd=current";
                "ctrl+b>%" = "launch --location=vsplit --cwd=current";

                "ctrl+b>h" = "neighboring_window left";
                "ctrl+b>j" = "neighboring_window down";
                "ctrl+b>k" = "neighboring_window up";
                "ctrl+b>l" = "neighboring_window right";

                "ctrl+b>[" = "kitten kitty_grab/grab.py";

                "ctrl+shift+o" = ''kitten hints --program "xdg-open"'';
              };

              # themes/light.conf, tab_bar.py, tab_nav.py and the kitty_grab
              # submodule stay as plain files in ~/.config/kitty - not
              # nix-managed.
              extraConfig = ''
                include themes/''${THEME}.conf
              '';
            };

            programs.waybar = {
              enable = true;

              settings = [
                {
                  # "layer" = "top";
                  position = "bottom";
                  height = 24;
                  # width = 1280;

                  "modules-left" = [ "sway/workspaces" ];
                  "modules-center" = [ "sway/window" ];
                  "modules-right" = [
                    "cpu"
                    "memory"
                    "disk"
                    "temperature"
                    "backlight"
                    "battery"
                    "pulseaudio"
                    "tray"
                    "clock"
                  ];

                  "sway/window".on-click = "swaymsg kill";

                  tray.spacing = 10;

                  clock = {
                    "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
                    "format-alt" = "{:%Y-%m-%d}";
                  };

                  cpu = {
                    format = "{usage}% ";
                    tooltip = false;
                  };

                  memory.format = "{}% ";

                  disk = {
                    interval = 30;
                    format = "{percentage_used}% ";
                  };

                  temperature = {
                    "critical-threshold" = 80;
                    format = "{temperatureC}°C {icon}";
                    "format-icons" = [
                      ""
                      ""
                      ""
                    ];
                  };

                  backlight = {
                    format = "{percent}% {icon}";
                    "format-icons" = [ "" ];
                  };

                  battery = {
                    states = {
                      warning = 30;
                      critical = 15;
                    };
                    format = "{capacity}% {icon}";
                    "format-charging" = "{capacity}% ";
                    "format-plugged" = "{capacity}% ";
                    "format-alt" = "{time} {icon}";
                    "format-icons" = [
                      ""
                      ""
                      ""
                      ""
                      ""
                    ];
                  };

                  pulseaudio = {
                    format = "{volume}% {icon} {format_source}";
                    "format-bluetooth" = "{volume}% {icon} {format_source}";
                    "format-bluetooth-muted" = " {icon} {format_source}";
                    "format-muted" = " {format_source}";
                    "format-source" = "{volume}% ";
                    "format-source-muted" = "";
                    "format-icons" = {
                      headphone = "";
                      "hands-free" = "";
                      headset = "";
                      phone = "";
                      portable = "";
                      car = "";
                      default = [
                        ""
                        ""
                        ""
                      ];
                    };
                    "on-click" = "pavucontrol";
                  };

                  "sway/workspaces" = {
                    "disable-scroll-wraparound" = true;
                    "enable-bar-scroll" = true;
                  };
                }
              ];

              style = ''
                window#waybar,
                #workspaces button {
                  background-color: rgba(16, 16, 16, 0.97);
                  /* Icon glyphs come from the font-awesome package (home.packages).
                     Regular text font comes first: Pango picks, per character, the
                     first font in this list that has a glyph for it. "Roboto" isn't
                     actually installed anywhere, so it (and Helvetica/Arial below)
                     get skipped entirely - Font Awesome 7 Free covers plain ASCII
                     too, so it was winning every character, icon or not. Noto Sans
                     (home.packages) is a real installed font, so it wins first now. */
                  font-family: "Noto Sans", "Font Awesome 7 Free", "Font Awesome 7 Brands", sans-serif;
                  font-size: 13px;
                  color: #d4d4d4;
                }

                button {
                  /* Use box-shadow instead of border so the text isn't offset */
                  box-shadow: inset 0 -2px transparent;
                  /* Avoid rounded borders under each button name */
                  border: none;
                  border-radius: 0;
                }

                /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
                button:hover {
                  background: inherit;
                  box-shadow: inset 0 -2px #d4d4d4;
                }

                #workspaces button {
                  padding: 0 5px;
                }

                #workspaces button:hover {
                  background: rgba(0, 0, 0, 0.2);
                }

                #workspaces button.focused {
                  background-color: #1a1a1a;
                  box-shadow: inset 0 -1px #4c4c4c;
                }

                #workspaces button.urgent {
                  background-color: #eb4d4b;
                }

                #clock,
                #battery,
                #cpu,
                #memory,
                #disk,
                #temperature,
                #backlight,
                #network,
                #pulseaudio,
                #wireplumber,
                #custom-media,
                #tray,
                #mode,
                #idle_inhibitor,
                #scratchpad,
                #mpd {
                  padding: 0 8px;
                }

                #window,
                #workspaces {
                  margin: 0 4px;
                }

                /* If workspaces is the leftmost module, omit left margin */
                .modules-left > widget:first-child > #workspaces {
                  margin-left: 0;
                }

                /* If workspaces is the rightmost module, omit right margin */
                .modules-right > widget:last-child > #workspaces {
                  margin-right: 0;
                }

                @keyframes blink {
                  to {
                    background-color: #d4d4d4;
                    color: #000000;
                  }
                }

                #battery.critical:not(.charging) {
                  background-color: #f53c3c;
                  animation-name: blink;
                  animation-duration: 0.5s;
                  animation-timing-function: linear;
                  animation-iteration-count: infinite;
                  animation-direction: alternate;
                }

                #network.disconnected {
                  background-color: #f53c3c;
                }

                #temperature.critical {
                  background-color: #eb4d4b;
                }
              '';
            };

            # Without this, xdg-desktop-portal-gtk/-wlr are installed as
            # packages but have no systemd/D-Bus service unit registering
            # them, so portal calls (file pickers, etc.) fail with
            # "Could not activate remote peer ...: unknown unit".
            xdg.portal = {
              enable = true;
              extraPortals = with homepkgs; [
                xdg-desktop-portal-gtk
                xdg-desktop-portal-wlr
              ];
              config.sway = {
                default = [
                  "wlr"
                  "gtk"
                ];
                "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
              };
            };

            # The D-Bus service files above declare SystemdService=, so
            # D-Bus asks systemd --user to start these units by name. But
            # systemd --user's UnitPath is a fixed list (see `systemctl
            # --user show -p UnitPath`) that does NOT include arbitrary
            # $XDG_DATA_DIRS entries like ~/.nix-profile/share/systemd/user
            # (only the flatpak dir gets that special-casing, hardcoded in
            # systemd itself) - only $XDG_DATA_HOME/systemd/user
            # (~/.local/share/systemd/user). Symlink the units there
            # directly so systemd can actually find and start them.
            xdg.dataFile."systemd/user/xdg-desktop-portal-gtk.service".source =
              "${homepkgs.xdg-desktop-portal-gtk}/share/systemd/user/xdg-desktop-portal-gtk.service";
            xdg.dataFile."systemd/user/xdg-desktop-portal-wlr.service".source =
              "${homepkgs.xdg-desktop-portal-wlr}/share/systemd/user/xdg-desktop-portal-wlr.service";

            wayland.windowManager.sway =
              let
                mod = "Mod4";

                workspaceBindings = homepkgs.lib.listToAttrs (
                  homepkgs.lib.flatten (
                    homepkgs.lib.genList (
                      i:
                      let
                        n = i + 1;
                        key = if n == 10 then "0" else toString n;
                      in
                      [
                        {
                          name = "${mod}+${key}";
                          value = "workspace number ${toString n}";
                        }
                        {
                          name = "${mod}+Control+${key}";
                          value = "workspace number ${toString (n + 10)}";
                        }
                        {
                          name = "${mod}+Shift+${key}";
                          value = "move container to workspace number ${toString n}";
                        }
                        {
                          name = "${mod}+Control+Shift+${key}";
                          value = "move container to workspace number ${toString (n + 10)}";
                        }
                      ]
                    ) 10
                  )
                );
              in
              {
                enable = true;
                checkConfig = true;
                systemd.enable = false;

                config = {
                  modifier = mod;
                  bars = [ ]; # waybar is started separately by sway-startup.sh

                  window = {
                    titlebar = false;
                    border = 1;
                    hideEdgeBorders = "both";
                    commands = [
                      {
                        criteria.title = "^(Picture in picture)|(Picture-in-Picture)$";
                        command = "floating enable, sticky enable, border none, move position 1000 0";
                      }
                      {
                        criteria.class = "REAPER";
                        command = "border normal, floating enable";
                      }
                      {
                        criteria.class = "yabridge-host.exe.so";
                        command = "border normal, floating enable";
                      }
                    ];
                  };

                  floating = {
                    titlebar = false;
                    border = 1;
                    modifier = "${mod} normal";
                    criteria = [
                      { app_id = "zenity"; }
                      { app_id = "xdg-desktop-portal-.*"; }
                      { title = "KeePassXC - (.*)Access Request"; }
                      { title = "Unlock Database - KeePassXC"; }
                      { app_id = "eu.web-eid.web-eid"; }
                      {
                        app_id = "thunar";
                        title = "^Rename";
                      }
                      { app_id = "org.kde.keditfiletype"; }
                    ];
                  };

                  focus.followMouse = "no";
                  gaps.smartBorders = "on";

                  input = {
                    "*" = {
                      xkb_layout = "us,ee";
                      xkb_options = "caps:escape,grp:win_space_toggle";
                    };
                    "type:touchpad" = {
                      tap = "enabled";
                      events = "disabled_on_external_mouse";
                    };
                  };

                  seat."seat0".hide_cursor = "3000";

                  modes.resize = {
                    Left = "resize shrink width 10 px or 10 ppt";
                    Down = "resize grow height 10 px or 10 ppt";
                    Up = "resize shrink height 10 px or 10 ppt";
                    Right = "resize grow width 10 px or 10 ppt";
                    Return = ''mode "default"'';
                    Escape = ''mode "default"'';
                  };

                  keybindings = homepkgs.lib.mkForce (
                    {
                      "${mod}+Return" = "exec foot";
                      "${mod}+q" = "kill";
                      "${mod}+d" =
                        ''exec j4-dmenu-desktop --no-generic --dmenu='wmenu -i -f "Monospace 11"' --term='foot' '';

                      "${mod}+h" = "focus left";
                      "${mod}+j" = "focus down";
                      "${mod}+k" = "focus up";
                      "${mod}+l" = "focus right";
                      "${mod}+Shift+h" = "move left";
                      "${mod}+Shift+j" = "move down";
                      "${mod}+Shift+k" = "move up";
                      "${mod}+Shift+l" = "move right";

                      "${mod}+s" = "split h";
                      "${mod}+v" = "split v";
                      "${mod}+f" = "fullscreen toggle";

                      "${mod}+Shift+space" = "floating toggle, sticky toggle";
                      "${mod}+a" = "focus parent";

                      "${mod}+Control+h" = "workspace prev";
                      "${mod}+Control+l" = "workspace next";
                      "${mod}+Tab" = "workspace back_and_forth";
                      "Alt+Tab" = "workspace back_and_forth";
                      "${mod}+Shift+Tab" = "workspace prev_on_output";
                      "Alt+Shift+Tab" = "workspace prev_on_output";

                      "${mod}+Shift+c" = "reload";
                      "${mod}+Shift+r" = "restart";
                      "${mod}+Shift+u" = "fullscreen toggle, fullscreen toggle";
                      "${mod}+Shift+e" = ''exec "swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'"'';
                      "${mod}+Shift+BackSpace" = "exec lock";
                      "${mod}+Shift+n" = "exec swaync-client -t -sw";
                      "${mod}+o" = "exec dolphin";
                      "${mod}+r" = "mode resize";
                    }
                    // workspaceBindings
                  );
                };

                extraConfig = ''
                  bindsym --release button2 kill
                '';
              };

            xdg.configFile."sway/config-main".text = ''
              include ./config
              exec bash $HOME/.scripts/sway-startup.sh
            '';

            xdg.configFile."sway/config-vnc".text = ''
              include ./config
              output HEADLESS-1 resolution 1920x1080
              exec bash $HOME/.scripts/sway-startup-vnc.sh
            '';

            programs.tint2 = {
              enable = true;
              extraConfig = ''
                #---- Generated by tint2conf aa1e ----
                # See https://gitlab.com/o9000/tint2/wikis/Configure for
                # full documentation of the configuration options.
                #-------------------------------------
                # Gradients
                #-------------------------------------
                # Backgrounds
                # Background 1: Panel
                rounded = 0
                border_width = 0
                border_sides = TBLR
                border_content_tint_weight = 0
                background_content_tint_weight = 0
                background_color = #000000 60
                border_color = #000000 30
                background_color_hover = #000000 60
                border_color_hover = #000000 30
                background_color_pressed = #000000 60
                border_color_pressed = #000000 30

                # Background 2: Default task, Iconified task
                rounded = 4
                border_width = 1
                border_sides = TBLR
                border_content_tint_weight = 0
                background_content_tint_weight = 0
                background_color = #777777 20
                border_color = #777777 30
                background_color_hover = #aaaaaa 22
                border_color_hover = #eaeaea 44
                background_color_pressed = #555555 4
                border_color_pressed = #eaeaea 44

                # Background 3: Active task
                rounded = 4
                border_width = 1
                border_sides = TBLR
                border_content_tint_weight = 0
                background_content_tint_weight = 0
                background_color = #777777 20
                border_color = #ffffff 40
                background_color_hover = #aaaaaa 22
                border_color_hover = #eaeaea 44
                background_color_pressed = #555555 4
                border_color_pressed = #eaeaea 44

                # Background 4: Urgent task
                rounded = 4
                border_width = 1
                border_sides = TBLR
                border_content_tint_weight = 0
                background_content_tint_weight = 0
                background_color = #aa4400 100
                border_color = #aa7733 100
                background_color_hover = #cc7700 100
                border_color_hover = #aa7733 100
                background_color_pressed = #555555 4
                border_color_pressed = #aa7733 100

                # Background 5: Tooltip
                rounded = 1
                border_width = 1
                border_sides = TBLR
                border_content_tint_weight = 0
                background_content_tint_weight = 0
                background_color = #222222 100
                border_color = #333333 100
                background_color_hover = #ffffaa 100
                border_color_hover = #000000 100
                background_color_pressed = #ffffaa 100
                border_color_pressed = #000000 100

                #-------------------------------------
                # Panel
                panel_items = TSC
                panel_size = 100% 30
                panel_margin = 0 0
                panel_padding = 2 0 2
                panel_background_id = 1
                wm_menu = 1
                panel_dock = 0
                panel_pivot_struts = 0
                panel_position = top center horizontal
                panel_layer = top
                panel_monitor = all
                panel_shrink = 0
                autohide = 0
                autohide_show_timeout = 0
                autohide_hide_timeout = 0.5
                autohide_height = 1
                strut_policy = follow_size
                panel_window_name = tint2
                disable_transparency = 1
                mouse_effects = 1
                font_shadow = 0
                mouse_hover_icon_asb = 100 0 10
                mouse_pressed_icon_asb = 100 0 0
                scale_relative_to_dpi = 0
                scale_relative_to_screen_height = 0

                #-------------------------------------
                # Taskbar
                taskbar_mode = single_desktop
                taskbar_hide_if_empty = 0
                taskbar_padding = 0 0 2
                taskbar_background_id = 0
                taskbar_active_background_id = 0
                taskbar_name = 1
                taskbar_hide_inactive_tasks = 0
                taskbar_hide_different_monitor = 0
                taskbar_hide_different_desktop = 0
                taskbar_always_show_all_desktop_tasks = 0
                taskbar_name_padding = 4 2
                taskbar_name_background_id = 0
                taskbar_name_active_background_id = 0
                taskbar_name_font_color = #e3e3e3 100
                taskbar_name_active_font_color = #ffffff 100
                taskbar_distribute_size = 0
                taskbar_sort_order = none
                task_align = left

                #-------------------------------------
                # Task
                task_text = 1
                task_icon = 1
                task_centered = 1
                urgent_nb_of_blink = 100000
                task_maximum_size = 150 35
                task_padding = 2 2 4
                task_tooltip = 1
                task_thumbnail = 0
                task_thumbnail_size = 210
                task_font_color = #ffffff 100
                task_background_id = 2
                task_active_background_id = 3
                task_urgent_background_id = 4
                task_iconified_background_id = 2
                mouse_left = toggle_iconify
                mouse_middle = none
                mouse_right = close
                mouse_scroll_up = toggle
                mouse_scroll_down = iconify

                #-------------------------------------
                # System tray (notification area)
                systray_padding = 0 4 2
                systray_background_id = 0
                systray_sort = ascending
                systray_icon_size = 24
                systray_icon_asb = 100 0 0
                systray_monitor = 1
                systray_name_filter =

                #-------------------------------------
                # Launcher
                launcher_padding = 2 4 2
                launcher_background_id = 0
                launcher_icon_background_id = 0
                launcher_icon_size = 24
                launcher_icon_asb = 100 0 0
                launcher_icon_theme_override = 0
                startup_notifications = 1
                launcher_tooltip = 1

                #-------------------------------------
                # Clock
                time1_format = %H:%M
                time2_format = %A %d %B
                time1_timezone =
                time2_timezone =
                clock_font_color = #ffffff 100
                clock_padding = 2 0
                clock_background_id = 0
                clock_tooltip =
                clock_tooltip_timezone =
                clock_lclick_command =
                clock_rclick_command = orage
                clock_mclick_command =
                clock_uwheel_command =
                clock_dwheel_command =

                #-------------------------------------
                # Battery
                battery_tooltip = 1
                battery_low_status = 10
                battery_low_cmd = xmessage 'tint2: Battery low!'
                battery_full_cmd =
                battery_font_color = #ffffff 100
                bat1_format =
                bat2_format =
                battery_padding = 1 0
                battery_background_id = 0
                battery_hide = 101
                battery_lclick_command =
                battery_rclick_command =
                battery_mclick_command =
                battery_uwheel_command =
                battery_dwheel_command =
                ac_connected_cmd =
                ac_disconnected_cmd =

                #-------------------------------------
                # Tooltip
                tooltip_show_timeout = 0.5
                tooltip_hide_timeout = 0.1
                tooltip_padding = 4 4
                tooltip_background_id = 5
                tooltip_font_color = #dddddd 100
              '';
            };

            programs.fzf = {
              enable = true;
              enableBashIntegration = true;

              defaultCommand = "fd --type f --hidden --no-ignore-vcs --exclude '.git/' --exclude 'node_modules/' --exclude 'vendor/'";
              fileWidget.command = "fd --type f --hidden --no-ignore-vcs --exclude '.git/' --exclude 'node_modules/' --exclude 'vendor/'";
              changeDirWidget.command = "fd --type d --hidden --no-ignore-vcs --exclude '.git/'";

              defaultOptions = [
                "--layout=reverse"
                "--marker='>'"
                "--pointer='>'"
                "--style=minimal"
                "--no-unicode"
              ];

              colors = {
                fg = "#000000";
                "fg+" = "#000000";
                bg = "#FFFFFF";
                "bg+" = "#F3F3F3";
                hl = "#008000";
                "hl+" = "#AF00DB";
                info = "#AF00DB";
                marker = "#AF00DB";
                prompt = "#AF00DB";
                spinner = "#AF00DB";
                pointer = "#AF00DB";
                header = "#008000";
                border = "#000000";
                label = "#AF00DB";
                query = "#000000";
              };
            };

            programs.direnv = {
              enable = true;
              enableBashIntegration = true;
            };

            programs.git = {
              enable = true;
              includes = [ { path = "~/.gitconfig_local"; } ];
              settings = {
                alias = {
                  st = "status";
                  co = "checkout";
                  ns = "diff --name-status";
                  lg = "!bash ~/.scripts/git/lg.sh";
                  lb = "!bash ~/.scripts/git/lb.sh";
                  logs = "!bash ~/.scripts/git/git-fzf.sh log";
                  reflogs = "!bash ~/.scripts/git/git-fzf.sh reflog";
                  msn = "!bash ~/.scripts/git/mergesquashn.sh";
                  snag = "!bash ~/.scripts/git/snag.sh";
                  squashall = "!bash ~/.scripts/git/squashall.sh";
                  sw = "!bash ~/.scripts/git/switch-fzf.sh";
                  stat = "!bash ~/.scripts/git/stat.sh";
                  alias = "!git config --get-regexp ^alias\\. | sed -e s/^alias\\.// -e s/\\ /\\ =\\ /";
                  web = "!gh repo view --web";
                };
                mergetool.keepBackup = false;
                diff = {
                  algorithm = "histogram";
                  mnemonicPrefix = true;
                  renames = true;
                };
                "mergetool \"nvim\"".cmd = ''NVIM_DIFF=1 nvim -f -c "Gvdiffsplit!" "$MERGED"'';
                merge.tool = "nvim";
                commit = {
                  gpgsign = true;
                  verbose = true;
                };
                gpg.format = "ssh";
                "gpg \"ssh\"".allowedSignersFile = "~/.config/git/allowed_signers";
                pull.ff = "only";
                pager = {
                  log = "diff-highlight | less";
                  show = "diff-highlight | less";
                  diff = "diff-highlight | less";
                };
                tag.sort = "version:refname";
                branch.sort = "-committerdate";
                init.defaultBranch = "main";
                push = {
                  default = "simple";
                  autoSetupRemote = true;
                  followTags = true;
                };
                fetch = {
                  prune = true;
                  pruneTags = true;
                  all = true;
                };
              };
            };

            programs.tmux = {
              enable = true;
              keyMode = "vi";
              historyLimit = 10000;
              escapeTime = 0;
              extraConfig = ''
                set -g pane-active-border-style fg=colour0,bg=default
                set -g pane-border-style fg=colour0,bg=default
                set -g popup-style fg=colour0,bg=default
                set -g popup-border-style fg=colour0,bg=default
                set -g set-clipboard on
                set -g status-style bg=default,fg=colour102
                set -g mouse on

                bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"
                bind-key c new-window -c "#{pane_current_path}"
                bind-key % split-window -h -c "#{pane_current_path}"
                bind-key '"' split-window -v -c "#{pane_current_path}"

                bind h select-pane -L
                bind j select-pane -D
                bind k select-pane -U
                bind l select-pane -R

                bind < resize-pane -L 1
                bind > resize-pane -R 1
                bind - resize-pane -D 1
                bind + resize-pane -U 1

                bind-key m switch-client -T move
                bind-key -T move Left  swap-window -d -t -1 \; switch-client -T move
                bind-key -T move Right swap-window -d -t +1 \; switch-client -T move
                bind-key -T move Escape switch-client -T root
                bind-key -T move Enter  switch-client -T root

                # Middle-click a window tab: close silently if idle (just a shell prompt),
                # otherwise ask for confirmation before killing it. confirm-before's -t
                # targets a client, not a window, so only the nested kill-window gets -t =.
                bind-key -n MouseDown2Status if-shell -F -t = "#{||:#{||:#{==:#{pane_current_command},bash},#{==:#{pane_current_command},zsh}},#{||:#{==:#{pane_current_command},fish},#{==:#{pane_current_command},sh}}}" "kill-window -t =" "confirm-before -p \"Kill window #{window_name} (#{pane_current_command} running)? (y/n)\" \"kill-window -t =\""
              '';
            };

            programs.firefox = {
              enable = true;
              package = homepkgs.firefox-bin;
              configPath = ".mozilla/firefox";

              # web-eid needs its native messaging host manifest linked in
              # for the extension to talk to the smart card app.
              nativeMessagingHosts = [ homepkgs.web-eid-app ];

              # Enterprise policies: unlike profile `settings` (which just
              # seeds prefs.js), these lock the prefs so they can't be
              # changed from about:config or the Settings UI.
              policies = {
                DisableTelemetry = true;
                DisablePocket = true;
                PasswordManagerEnabled = false;
                NetworkPrediction = false;
                DNSOverHTTPS = {
                  Enabled = false;
                  Locked = true;
                };
                EnableTrackingProtection = {
                  Value = true;
                  Locked = true;
                  Category = "strict";
                };

                Preferences = {
                  # Reopen previous windows and tabs on startup.
                  "browser.startup.page" = {
                    Value = 3;
                    Status = "locked";
                  };

                  # Disable built-in AI features.
                  "browser.ml.chat.enabled" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.ml.chat.page" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.ml.linkPreview.enabled" = {
                    Value = false;
                    Status = "locked";
                  };
                  "extensions.ml.enabled" = {
                    Value = false;
                    Status = "locked";
                  };
                  "pdfjs.enableAltText" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.smartwindow.memories.generateFromConversation" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.smartwindow.memories.generateFromHistory" = {
                    Value = false;
                    Status = "locked";
                  };

                  # Disable sponsored content on the new tab page.
                  "browser.newtabpage.activity-stream.showSponsored" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.newtabpage.activity-stream.showSponsoredTopSites" = {
                    Value = false;
                    Status = "locked";
                  };

                  # Disable smart tab groups and translations.
                  "browser.tabs.groups.smart.enabled" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.tabs.groups.smart.userEnabled" = {
                    Value = false;
                    Status = "locked";
                  };
                  "browser.translations.enable" = {
                    Value = false;
                    Status = "locked";
                  };

                  # Use 1Password instead of Firefox's built-in card autofill.
                  "extensions.formautofill.creditCards.enabled" = {
                    Value = false;
                    Status = "locked";
                  };

                  "sidebar.visibility" = {
                    Value = "hide-on-close";
                    Status = "locked";
                  };
                };
              };

              profiles.${username} = {
                id = 0;

                settings = {
                  "extensions.autoDisableScopes" = 0;
                };

                extensions.packages = with firefoxAddons; [
                  vimium
                  ublock-origin
                  multi-account-containers
                  onepassword-password-manager
                  web-eid
                ];
              };
            };

            # Multi-Account Containers has no Chromium equivalent (relies on
            # Firefox's contextual identities API), so it's omitted here.
            programs.brave-origin = {
              enable = true;
              package = homepkgs.brave-origin;

              # web-eid needs its native messaging host manifest linked in
              # for the extension to talk to the smart card app.
              nativeMessagingHosts = [ homepkgs.web-eid-app ];

              # Middle-click autoscroll is disabled by default on Linux,
              # since middle-click is traditionally reserved for primary
              # selection paste there.
              commandLineArgs = [ "--enable-blink-features=MiddleClickAutoscroll" ];

              extensions = [
                { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
                { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
                { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1Password
                { id = "ncibgoaomkmdpilpocfeponihegamlic"; } # Web eID
              ];
            };

            # Brave reads enterprise policies from /etc/brave/policies/managed,
            # which lives outside $HOME - requires sudo on every activation.
            home.activation.bravePolicies = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              $DRY_RUN_CMD /usr/bin/sudo install -Dm644 ${bravePolicyFile} /etc/brave/policies/managed/policy.json
            '';

            programs.thunderbird = {
              enable = true;
              package = homepkgs.thunderbird;

              profiles.${username} = {
                isDefault = true;

                settings = {
                  # Auto-enable the extensions below instead of requiring a
                  # manual enable in the Add-ons Manager.
                  "extensions.autoDisableScopes" = 0;

                  # Vertical layout: folder pane, message list and message
                  # pane side by side (0 = classic, 1 = wide).
                  "mail.pane_config.dynamic" = 2;

                  # Compact density (1 = default, 2 = relaxed).
                  "mail.uidensity" = 0;

                  # Table view for the message list instead of cards.
                  "mail.threadpane.listview" = 1;

                  # Threaded, sorted by date ascending so the newest message
                  # is at the bottom. Only applies to folders the first time
                  # they are opened - each folder stores its own sort after
                  # that, changed via View > Sort By / Apply Views To Folder.
                  "mailnews.default_view_flags" = 1;
                  "mailnews.default_sort_type" = 18;
                  "mailnews.default_sort_order" = 1;
                };

                extensions = [
                  dkimVerifierExtension
                ];
              };
            };

            programs.mpv = {
              enable = true;
              config = {
                profile = "gpu-hq";
                hwdec = "auto";
                keep-open = "yes";
                save-position-on-quit = "yes";
                force-seekable = "yes";
                vo = "gpu-next";
                gpu-api = "vulkan";
                volume = 100;
                volume-max = 100;
                script-opts = "ytdl_hook-ytdl_path=yt-dlp";
              };
              bindings = {
                WHEEL_UP = "seek 1";
                WHEEL_DOWN = "seek -1";
                "Shift+WHEEL_UP" = "add volume 2";
                "Shift+WHEEL_DOWN" = "add volume -2";
                MBTN_MID = "quit";
              };
            };

            qt = {
              enable = true;
              platformTheme.name = "qt6ct";
              qt6ctSettings = {
                Appearance = {
                  custom_palette = false;
                  standard_dialogs = "default";
                  style = "Fusion";
                };
                Fonts = {
                  fixed = "\"Monospace,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\"";
                  general = "\"Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular\"";
                };
                Interface = {
                  activate_item_on_single_click = 2;
                  buttonbox_layout = 0;
                  cursor_flash_time = 1000;
                  dialog_buttons_have_icons = 1;
                  double_click_interval = 400;
                  gui_effects = "@Invalid()";
                  keyboard_scheme = 2;
                  menus_have_icons = true;
                  show_shortcuts_in_context_menus = true;
                  stylesheets = "@Invalid()";
                  toolbutton_style = 4;
                  underline_shortcut = 1;
                  wheel_scroll_lines = 3;
                };
                Troubleshooting = {
                  force_raster_widgets = 1;
                };
              };
            };

            fonts.fontconfig = {
              enable = true;
              antialiasing = true;
              hinting = "slight";
              subpixelRendering = "none";

              # No dedicated home-manager option for embeddedbitmap.
              configFile."local-embeddedbitmap" = {
                enable = true;
                text = ''
                  <?xml version="1.0"?>
                  <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
                  <fontconfig>
                    <match target="font">
                      <edit mode="assign" name="embeddedbitmap">
                        <bool>false</bool>
                      </edit>
                    </match>
                  </fontconfig>
                '';
              };
            };

            programs.github-copilot-cli = {
              enable = true;
              package = homepkgs.github-copilot-cli;

              # Matches the pre-existing config location; the module
              # defaults to ~/.copilot instead of the XDG config dir.
              configDir = "/home/${username}/.config/copilot";

              settings = {
                theme = "auto";
                banner = "never";
              };
            };

            # No `settings` block - the module always writes
            # ~/.claude/settings.json as a read-only store symlink with no
            # mutable option, which breaks anything Claude Code itself needs
            # to write there (/effort, /theme, /plugin, ...). Left for the
            # CLI to own outright; set theme/notifications/plugins once by
            # hand after switching.
            programs.claude-code = {
              enable = true;
              package = homepkgs.claude-code;
            };

            nix.package = homepkgs.nix;
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            xdg.enable = true;

            # Replaces the manual `xdg-user-dirs-update` call from
            # postinstall/3_config.sh, which used to run before dotfiles/
            # home-manager even existed on a fresh install. This runs as
            # part of `home-manager switch` activation instead.
            xdg.userDirs.enable = true;
            xdg.userDirs.createDirectories = true;
            xdg.userDirs.setSessionVariables = false;

            xdg.desktopEntries.colorpick = {
              name = "Color Picker";
              exec = ''/usr/bin/bash -c "bash ~/.scripts/colorpick.sh"'';
              categories = [ "Graphics" ];
              settings.Keywords = "color;colorpick;";
            };

            xdg.desktopEntries.screenshot = {
              name = "Screenshot";
              exec = ''/usr/bin/bash -c "bash ~/.scripts/screenshot.sh"'';
              categories = [ "Graphics" ];
              settings.Keywords = "screenshot;";
            };

            home.file.".config/yabridgectl/config.toml".source =
              (homepkgs.formats.toml { }).generate "yabridgectl-config.toml"
                {
                  plugin_dirs = [ "/home/${username}/Shared/Audio/win-plugins/Plugins" ];
                  vst2_location = "centralized";
                  no_verify = false;
                  blacklist = [ ];
                };

            home.file."Shared/Audio/win-plugins/custom.reg".text = ''
              Windows Registry Editor Version 5.00

              [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
              "Guitar Pro 5 (TrueType)"="Guitar Pro 5.ttf"

              [HKEY_LOCAL_MACHINE\Software\Wow6432Node\Arobas Music\Guitar Pro 5]
              "InstallFolder"="C:\\Program Files (x86)\\Guitar Pro 5"
            '';

            home.file."Shared/Audio/win-plugins/AppData/Roaming/Ugritone/Ampenstein/config.xml".text = ''
              <?xml version="1.0" encoding="UTF-8"?>

              <root pluginDataPath="C:\users\${username}\win-plugins\Plugins\Ugritone\Ampenstein\Processors"
                    IRPath="C:\users\${username}\win-plugins\Plugins\Ugritone\Ampenstein\Impulse Responses"
                    flipChannels="0" temporarySaveAmpStatesForEachSlot="1" UserPresetsPath="C:\users\${username}\win-plugins\Plugins\Ugritone\Ampenstein\User Presets"
                    BGImagePath=""/>
            '';

            home.file."Shared/Audio/win-plugins/AppData/Roaming/Ugritone/VerbCore/config.cfg".text = ''
              <?xml version="1.0" encoding="UTF-8"?>

              <root userDataPath="C:\users\${username}\win-plugins\Plugins\Ugritone\VerbCore"/>
            '';

            home.file.".config/yamllint/config".source =
              (homepkgs.formats.yaml { }).generate "yamllint-config"
                {
                  "yaml-files" = [
                    "*.yaml"
                    "*.yml"
                    ".yamllint"
                  ];

                  rules = {
                    anchors = "enable";
                    braces = "enable";
                    brackets = "enable";
                    colons = "enable";
                    commas = "enable";
                    comments = {
                      require-starting-space = true;
                      ignore-shebangs = true;
                      min-spaces-from-content = 1;
                    };
                    comments-indentation.level = "warning";
                    document-end = "disable";
                    document-start.level = "warning";
                    empty-lines = "enable";
                    empty-values = "disable";
                    float-values = "disable";
                    hyphens = "enable";
                    indentation = {
                      spaces = "consistent";
                      indent-sequences = "consistent";
                      check-multi-line-strings = false;
                    };
                    key-duplicates = "enable";
                    key-ordering = "disable";
                    line-length = "disable";
                    new-line-at-end-of-file = "enable";
                    new-lines = "enable";
                    octal-values = "disable";
                    quoted-strings = "disable";
                    trailing-spaces = "enable";
                    truthy.level = "warning";
                  };
                };

            home.file.".config/containers/storage.conf".source =
              (homepkgs.formats.toml { }).generate "containers-storage.conf"
                {
                  storage.driver = "overlay";
                };

            # This is a *template* unit (%i = remote name), instantiated
            # per-remote at runtime by postinstall/6_rclone_mount.sh via
            # `systemctl --user enable --now rclone@$remote`. It's kept as
            # raw text rather than systemd.user.services."rclone@" because
            # that module always turns Install.WantedBy into an eager
            # ~/.config/systemd/user/default.target.wants/rclone@.service
            # symlink pointing at the bare, uninstantiated template - which
            # systemd can't start and fails at every login. Writing the file
            # directly avoids that footgun while still needing the
            # [Install] section for `systemctl enable` to work per-instance.
            # https://github.com/rclone/rclone/wiki/Systemd-rclone-mount#systemd
            xdg.configFile."systemd/user/rclone@.service".text = ''
              [Unit]
              Description=RClone mount of users remote %i using filesystem permissions
              Documentation=http://rclone.org/docs/
              After=network-online.target


              [Service]
              Type=notify
              #Set up environment
              Environment=REMOTE_NAME="%i"
              Environment=REMOTE_PATH="/"
              Environment=MOUNT_DIR="/mnt/%u/%i"
              Environment=POST_MOUNT_SCRIPT=""
              Environment=RCLONE_CONF="%h/.config/rclone/rclone.conf"
              Environment=RCLONE_TEMP_DIR="%h/.cache/rclone/%u/%i"
              Environment=RCLONE_RC_ON="false"

              #Default arguments for rclone mount. Can be overridden in the environment file
              Environment=RCLONE_MOUNT_ATTR_TIMEOUT="1s"
              #TODO: figure out default for the following parameter
              Environment=RCLONE_MOUNT_DAEMON_TIMEOUT="UNKNOWN_DEFAULT"
              Environment=RCLONE_MOUNT_DIR_CACHE_TIME="1m"
              Environment=RCLONE_MOUNT_DIR_PERMS="0777"
              Environment=RCLONE_MOUNT_FILE_PERMS="0666"
              Environment=RCLONE_MOUNT_GID="%G"
              Environment=RCLONE_MOUNT_MAX_READ_AHEAD="128k"
              Environment=RCLONE_MOUNT_POLL_INTERVAL="1m0s"
              Environment=RCLONE_MOUNT_UID="%U"
              Environment=RCLONE_MOUNT_UMASK="022"
              Environment=RCLONE_MOUNT_VFS_CACHE_MAX_AGE="1h0m0s"
              Environment=RCLONE_MOUNT_VFS_CACHE_MAX_SIZE="off"
              Environment=RCLONE_MOUNT_VFS_CACHE_MODE="writes"
              Environment=RCLONE_MOUNT_VFS_CACHE_POLL_INTERVAL="1m0s"
              Environment=RCLONE_MOUNT_VFS_READ_CHUNK_SIZE="128M"
              Environment=RCLONE_MOUNT_VFS_READ_CHUNK_SIZE_LIMIT="off"
              #TODO: figure out default for the following parameter
              Environment=RCLONE_MOUNT_VOLNAME="UNKNOWN_DEFAULT"

              #Overwrite default environment settings with settings from the file if present
              EnvironmentFile=-%h/.config/rclone/%i.env

              #Check that rclone is installed
              ExecStartPre=${homepkgs.coreutils}/bin/test -x ${homepkgs.rclone}/bin/rclone

              #Check the mount directory
              ExecStartPre=${homepkgs.coreutils}/bin/test -d "''${MOUNT_DIR}"
              ExecStartPre=${homepkgs.coreutils}/bin/test -w "''${MOUNT_DIR}"
              #TODO: Add test for MOUNT_DIR being empty -> ExecStartPre=${homepkgs.coreutils}/bin/test -z "$(ls -A "''${MOUNT_DIR}")"

              #Check the rclone configuration file
              ExecStartPre=${homepkgs.coreutils}/bin/test -f "''${RCLONE_CONF}"
              ExecStartPre=${homepkgs.coreutils}/bin/test -r "''${RCLONE_CONF}"
              #TODO: add test that the remote is configured for the rclone configuration

              #Mount rclone fs
              ExecStart=${homepkgs.rclone}/bin/rclone mount \
                          --config="''${RCLONE_CONF}" \
              #See additional items for access control below for information about the following 2 flags
              #            --allow-other \
              #            --default-permissions \
                          --rc="''${RCLONE_RC_ON}" \
                          --cache-tmp-upload-path="''${RCLONE_TEMP_DIR}/upload" \
                          --cache-chunk-path="''${RCLONE_TEMP_DIR}/chunks" \
                          --cache-workers=8 \
                          --cache-writes \
                          --cache-dir="''${RCLONE_TEMP_DIR}/vfs" \
                          --cache-db-path="''${RCLONE_TEMP_DIR}/db" \
                          --no-modtime \
                          --drive-use-trash \
                          --stats=0 \
                          --checkers=16 \
                          --bwlimit=40M \
                          --cache-info-age=60m \
                          --attr-timeout="''${RCLONE_MOUNT_ATTR_TIMEOUT}" \
              #TODO: Include this once a proper default value is determined
              #           --daemon-timeout="''${RCLONE_MOUNT_DAEMON_TIMEOUT}" \
                          --dir-cache-time="''${RCLONE_MOUNT_DIR_CACHE_TIME}" \
                          --dir-perms="''${RCLONE_MOUNT_DIR_PERMS}" \
                          --file-perms="''${RCLONE_MOUNT_FILE_PERMS}" \
                          --gid="''${RCLONE_MOUNT_GID}" \
                          --max-read-ahead="''${RCLONE_MOUNT_MAX_READ_AHEAD}" \
                          --poll-interval="''${RCLONE_MOUNT_POLL_INTERVAL}" \
                          --uid="''${RCLONE_MOUNT_UID}" \
                          --umask="''${RCLONE_MOUNT_UMASK}" \
                          --vfs-cache-max-age="''${RCLONE_MOUNT_VFS_CACHE_MAX_AGE}" \
                          --vfs-cache-max-size="''${RCLONE_MOUNT_VFS_CACHE_MAX_SIZE}" \
                          --vfs-cache-mode="''${RCLONE_MOUNT_VFS_CACHE_MODE}" \
                          --vfs-cache-poll-interval="''${RCLONE_MOUNT_VFS_CACHE_POLL_INTERVAL}" \
                          --vfs-read-chunk-size="''${RCLONE_MOUNT_VFS_READ_CHUNK_SIZE}" \
                          --vfs-read-chunk-size-limit="''${RCLONE_MOUNT_VFS_READ_CHUNK_SIZE_LIMIT}" \
              #TODO: Include this once a proper default value is determined
              #            --volname="''${RCLONE_MOUNT_VOLNAME}"
                          "''${REMOTE_NAME}:''${REMOTE_PATH}" "''${MOUNT_DIR}"

              #Execute Post Mount Script if specified
              ExecStartPost=${homepkgs.bash}/bin/sh -c "''${POST_MOUNT_SCRIPT}"

              #Unmount rclone fs
              ExecStop=${homepkgs.fuse}/bin/fusermount -u "''${MOUNT_DIR}"

              #Restart info
              Restart=always
              RestartSec=10

              [Install]
              WantedBy=default.target
            '';

          }
        ];
      };
    };
}
