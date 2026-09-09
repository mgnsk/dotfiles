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

    reaper-flake = {
      url = "github:9Prestidigitator/reaper-flake";
      inputs.nixpkgs.follows = "nixpkgs-home";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-home";
      inputs.home-manager.follows = "home-manager";
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

      audio = import ./nix/audio.nix { inherit audiopkgs homepkgs username; };
      inherit (audio)
        winePkgs
        clapPlugins
        lv2Plugins
        vst3Plugins
        ;

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

      homePkgs =
        with homepkgs;
        [
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
          jgmenu
          openbox
          pavucontrol
          picom
          powertop
          qdigidoc
          qt6Packages.qt6ct
          qt6Packages.qtimageformats
          slurp
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
          kdePackages.dolphin
          networkmanagerapplet
          blueman
          xwayland
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ]
        # Plugins, wine and yabridge come from nixpkgs-audio rather than
        # nixpkgs-home (see nix/audio.nix) so REAPER works standalone,
        # with no separate dev shell needed.
        ++ winePkgs
        ++ clapPlugins
        ++ lv2Plugins
        ++ vst3Plugins;

      # Roots for closurePositions below. nixpkgs-home is derived from the
      # actual build output (home-manager's merged package list) rather than
      # a hand-curated list, so newly added programs/packages are
      # automatically included without maintenance. nixpkgs-audio has to be
      # hand-curated instead, since its packages are just plain list entries
      # merged into that same home.packages rather than a separate output of
      # their own to derive it from.
      packageSets = {
        nixpkgs-home = self.homeConfigurations.${username}.config.home.packages;
        nixpkgs-audio = winePkgs ++ clapPlugins ++ lv2Plugins ++ vst3Plugins;
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
      inherit packageSets closurePositions;

      formatter.${system} = homepkgs.nixfmt;

      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = homepkgs;
        modules = [
          inputs.reaper-flake.homeModules.reaper
          inputs.plasma-manager.homeModules.plasma-manager
          audio.homeModule
          (
            {
              lib,
              pkgs,
              config,
              ...
            }:
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

              # Nix-built GUI programs link against
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

                initExtra = # bash
                  ''
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

                profileExtra = # bash
                  ''
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

                    		exec sway --config ~/.config/sway/config
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

              programs.waybar = {
                enable = true;

                systemd = {
                  enable = true;
                  targets = [ "sway-session.target" ];
                };

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

                style = # css
                  ''
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

              # xdg-desktop-portal-wlr.service's upstream unit only checks
              # ConditionEnvironment=WAYLAND_DISPLAY is *set*, not that it
              # names a live socket. On a sway restart (crash, session churn)
              # the compositor can come back on a new socket (wayland-1
              # instead of wayland-0, say), and this unit - PartOf=
              # graphical-session.target - gets pulled down and restarted
              # before systemd --user's environment has been re-imported with
              # the new value, so it dies trying to connect to the old,
              # now-gone socket. With the vendor unit's default
              # Restart=on-failure (100ms backoff) and no StartLimitBurst
              # override, that burns through the default 5-in-10s restart
              # budget in under a second and the unit stays dead even once
              # the environment catches up. This is a systemd drop-in (not a
              # home-manager systemd.user.services entry) because the latter
              # would replace the whole unit, including the store-path-pinned
              # ExecStart= above that home-manager doesn't otherwise know
              # about.
              xdg.configFile."systemd/user/xdg-desktop-portal-wlr.service.d/restart-backoff.conf".text = # ini
                ''
                  [Unit]
                  StartLimitIntervalSec=30
                  StartLimitBurst=5

                  [Service]
                  RestartSec=2
                '';

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

                  systemd = {
                    enable = true;
                    variables = [
                      "DISPLAY"
                      "SWAYSOCK"
                      "WAYLAND_DISPLAY"
                      "XDG_CURRENT_DESKTOP"
                    ];
                  };

                  config = {
                    modifier = mod;
                    bars = [ ]; # waybar is a systemd service, see programs.waybar.systemd below

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

                  extraConfig = # sway
                    ''
                      bindsym --release button2 kill
                    '';
                };

              # Sway startup companions, as systemd --user services bound to
              # sway-session.target.
              services.swayidle =
                let
                  # swayidle.service's generated unit pins PATH to just bash's
                  # own store path, so PATH-reliant commands like `lock` (from
                  # home.sessionPath) and `swaymsg` (nix-installed sway) won't
                  # resolve there the way they do from an interactive shell or
                  # sway's own `exec` lines - spell them out explicitly. Also,
                  # systemd's ExecStart= does its own "$VAR" substitution using
                  # only the unit's Environment= (which doesn't set HOME), so
                  # "$HOME" there silently expands to empty - use the literal
                  # path instead.
                  lock = "/home/${username}/.scripts/bin/lock";
                  swaymsg = "${homepkgs.sway}/bin/swaymsg";
                in
                {
                  enable = true;
                  systemdTargets = [ "sway-session.target" ];

                  timeouts = [
                    {
                      timeout = 3600;
                      command = lock;
                    }
                    {
                      timeout = 3601;
                      command = ''${swaymsg} "output * dpms off"'';
                      resumeCommand = ''${swaymsg} "output * dpms on"'';
                    }
                  ];

                  events.before-sleep = lock;
                };

              services.network-manager-applet.enable = true;

              services.blueman-applet = {
                enable = true;
                systemdTargets = [ "sway-session.target" ];
              };

              services.swaync.enable = true;

              services.gammastep = {
                enable = true;
                provider = "manual";
                latitude = 59.436962;
                longitude = 24.753574;
                temperature.night = 5000;
                tray = true;
              };

              systemd.user.services = {
                # Tray-icon apps (blueman-applet, network-manager-applet,
                # swaync, gammastep's tray indicator) need a
                # StatusNotifierWatcher on the session bus before they start,
                # or their icons silently fail to register. Waybar's process
                # starting (After=waybar.service) doesn't guarantee its tray
                # module has actually registered the watcher yet, so poll for
                # it too, same as sway-startup.sh used to.
                # Reference: https://github.com/Alexays/Waybar/discussions/1828#discussioncomment-10126615
                #
                # DefaultDependencies=false on this unit (and waybar, swayidle,
                # blueman-applet below): target units automatically complement
                # every unit in their effective Wants= (i.e. anything
                # WantedBy=sway-session.target) with a matching After=, unless
                # that unit sets DefaultDependencies=no (systemd.target(5)).
                # Since this unit chains After=waybar.service, and waybar.service
                # is itself After=sway-session.target, that auto-added
                # "sway-session.target After=wait-for-tray.service" closes a
                # real ordering cycle - systemd silently drops the losing
                # units' start jobs to break it, which is why waybar (and
                # swayidle, and anything chained through wait-for-tray) can
                # fail to start at all.
                wait-for-tray = {
                  Unit = {
                    Description = "Block until a tray (StatusNotifierWatcher) is registered on the session bus";
                    After = [ "waybar.service" ];
                    Wants = [ "waybar.service" ];
                    DefaultDependencies = false;
                  };
                  Service = {
                    Type = "oneshot";
                    ExecStart = "${homepkgs.writeShellScript "wait-for-tray" ''
                      until dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep -q org.kde.Status; do
                        sleep 0.2
                      done
                    ''}";
                  };
                  Install.WantedBy = [ "sway-session.target" ];
                };

                blueman-applet.Unit = {
                  After = [ "wait-for-tray.service" ];
                  Wants = [ "wait-for-tray.service" ];
                  DefaultDependencies = false;
                };

                # waybar and swayidle both carry an explicit
                # After=sway-session.target (waybar from programs.waybar's own
                # module, swayidle from services.swayidle below) - see the
                # wait-for-tray comment above for why that needs
                # DefaultDependencies=false here too, to stop
                # sway-session.target auto-ordering itself after them right
                # back.
                waybar.Unit.DefaultDependencies = false;
                swayidle.Unit.DefaultDependencies = false;

                network-manager-applet.Unit = {
                  After = [ "wait-for-tray.service" ];
                  Wants = [ "wait-for-tray.service" ];
                };

                swaync.Unit = {
                  After = [ "wait-for-tray.service" ];
                  Wants = [ "wait-for-tray.service" ];
                };

                gammastep.Unit = {
                  After = [ "wait-for-tray.service" ];
                  Wants = [ "wait-for-tray.service" ];
                };

                # No home-manager module packages this - it's a plain
                # Arch/pacman system binary, not a nix derivation.
                polkit-mate-authentication-agent = {
                  Unit.Description = "MATE PolicyKit authentication agent";
                  Service = {
                    Type = "simple";
                    ExecStart = "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1";
                    Restart = "on-failure";
                  };
                  Install.WantedBy = [ "sway-session.target" ];
                };

                audio-idle-inhibit = {
                  Unit.Description = "Block idle while audio is playing or being captured";
                  Service = {
                    Type = "simple";
                    ExecStart = "${homepkgs.writeShellScript "audio-idle-inhibit" ''
                      inhibit_duration=25
                      sleep_duration=5

                      while true; do
                        if pactl list | grep -q RUNNING; then
                          echo "INHIBITING" >&2
                          systemd-inhibit \
                            --what idle \
                            --who systemd-audio-idle-inhibit \
                            --why "audio output or input active" \
                            --mode block \
                            sh -c "sleep $inhibit_duration"
                        else
                          echo "WAITING" >&2
                          sleep $sleep_duration
                        fi
                      done
                    ''}";
                  };
                  Install.WantedBy = [ "sway-session.target" ];
                };
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
                extraConfig = # tmux
                  ''
                    set -g pane-active-border-style fg=colour0,bg=default
                    set -g pane-border-style fg=colour0,bg=default
                    set -g popup-style fg=colour0,bg=default
                    set -g popup-border-style fg=colour0,bg=default
                    set -g set-clipboard on
                    set -g status-style bg=default,fg=colour102
                    set -g mouse on
                    set -g renumber-windows on

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
              home.activation.bravePolicies =
                inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
                  # bash
                  ''
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
                  text = # xml
                    ''
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

              programs.tint2 = {
                enable = true;
                extraConfig = # ini
                  ''
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

              # dolphinrc/kdeglobals are structured KDE-INI files with no
              # dedicated home-manager module; plasma-manager's configFile
              # generator (group -> key -> value) covers them without
              # resorting to raw text. overrideConfig is left at its default
              # (false) so only the keys declared here are touched - no other
              # KDE rc files get reset.
              programs.plasma.enable = true;

              programs.plasma.configFile."dolphinrc" = {
                General = {
                  BrowseThroughArchives = true;
                  RememberOpenedTabs = false;
                  ShowFullPath = true;
                  Version = 202;
                };
                IconsMode.PreviewSize = 128;
                "KFileDialog Settings" = {
                  "Places Icons Auto-resize" = false;
                  "Places Icons Static Size" = 22;
                };
                MainWindow.MenuBar = "Disabled";
                PreviewSettings.Plugins = "appimagethumbnail,audiothumbnail,glycin-heif,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,heif,imagethumbnail,glycin-image-rs,jpegthumbnail,glycin-jxl,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,mobithumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,glycin-svg,svgthumbnail,ffmpegthumbs,webp-pixbuf";
              };

              programs.plasma.configFile."kdeglobals" = {
                KDE.ShowDeleteCommand = true;
                PreviewSettings = {
                  EnableRemoteFolderThumbnail = false;
                  MaximumRemoteSize = 1047527424;
                };
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

              # rc.xml: Openbox's own compiled-in mouse defaults (see
              # bind_default_mouse() in openbox/config.c), restated because
              # supplying a <mouse> section at all wipes every default
              # binding rather than overriding individual ones. The only
              # change from stock is Frame drag: Alt+Left/Alt+Middle become
              # Super+Left/Super+Middle, so Alt+click/drag reaches clients
              # (Reaper) untouched. Everything not listed here (keyboard,
              # theme, focus, desktops, ...) is left at Openbox's defaults.
              xdg.configFile."openbox/rc.xml".text = ''
                <?xml version="1.0" encoding="UTF-8"?>
                <openbox_config xmlns="http://openbox.org/3.4/rc">
                  <mouse>
                    <context name="Client Desktop">
                      <mousebind button="Left Middle Right" action="Press">
                        <action name="Focus"/>
                      </mousebind>
                    </context>

                    <context name="Titlebar Bottom BLCorner BRCorner TLCorner TRCorner Close Maximize Iconify Icon AllDesktops Shade">
                      <mousebind button="Left" action="Press">
                        <action name="Focus"/>
                      </mousebind>
                    </context>

                    <context name="Client Titlebar BLCorner BRCorner TLCorner TRCorner Close Maximize Iconify Icon AllDesktops Shade">
                      <mousebind button="Left" action="Click">
                        <action name="Raise"/>
                      </mousebind>
                    </context>

                    <context name="Titlebar">
                      <mousebind button="Middle" action="Click">
                        <action name="Lower"/>
                      </mousebind>
                      <mousebind button="Left" action="Drag">
                        <action name="Move"/>
                      </mousebind>
                    </context>

                    <context name="Close">
                      <mousebind button="Left" action="Click">
                        <action name="Close"/>
                      </mousebind>
                    </context>

                    <context name="Maximize">
                      <mousebind button="Left" action="Click">
                        <action name="ToggleMaximize"/>
                      </mousebind>
                    </context>

                    <context name="Iconify">
                      <mousebind button="Left" action="Click">
                        <action name="Iconify"/>
                      </mousebind>
                    </context>

                    <context name="AllDesktops">
                      <mousebind button="Left" action="Click">
                        <action name="ToggleOmnipresent"/>
                      </mousebind>
                    </context>

                    <context name="Shade">
                      <mousebind button="Left" action="Click">
                        <action name="ToggleShade"/>
                      </mousebind>
                    </context>

                    <context name="TLCorner TRCorner BLCorner BRCorner Top Bottom Left Right">
                      <mousebind button="Left" action="Drag">
                        <action name="Resize"/>
                      </mousebind>
                    </context>

                    <context name="Frame">
                      <mousebind button="W-Left" action="Drag">
                        <action name="Move"/>
                      </mousebind>
                      <mousebind button="W-Middle" action="Drag">
                        <action name="Resize"/>
                      </mousebind>
                    </context>
                  </mouse>
                </openbox_config>
              '';

              # jgmenu (github.com/jgmenu/jgmenu) replaces obmenu-generator:
              # right-click on the desktop still opens this static Openbox
              # pipe-menu (unchanged rc.xml/mousebind), but its one entry now
              # just launches jgmenu's own self-drawn app menu instead of
              # piping obmenu-generator-generated XML into Openbox's menu
              # renderer. jgmenu builds its XDG application list itself
              # (csv_cmd defaults to "apps"), so no separate desktop-file-path
              # config is needed the way obmenu-generator required.
              xdg.configFile."openbox/menu.xml".text = ''
                <?xml version="1.0" encoding="utf-8"?>
                <openbox_menu>
                    <menu id="root-menu" label="OpenBox 3">
                        <item label="Applications">
                            <action name="Execute">
                                <command>jgmenu_run</command>
                            </action>
                        </item>
                        <separator/>
                        <item label="Terminal">
                            <action name="Execute">
                                <command>xterm</command>
                            </action>
                        </item>
                        <separator/>
                        <item label="Exit">
                            <action name="Exit"/>
                        </item>
                    </menu>
                </openbox_menu>
              '';

              xdg.configFile."openbox/autostart".text = # bash
                ''
                  picom -b --fade-in-step=0.1 --fade-out-step=0.2
                  tint2 &
                '';

              home.file.".xinitrc".text = # bash
                ''
                  #!/bin/sh

                  exec openbox-session
                '';

              # KXMLGUI toolbar/menu layout - XML, not INI, so it doesn't fit
              # plasma-manager's configFile group->key->value generator.
              # Lives under XDG_DATA_HOME, not XDG_CONFIG_HOME.
              xdg.dataFile."kxmlgui5/dolphin/dolphinui.rc".text = # xml
                ''
                  <?xml version='1.0'?>
                  <!DOCTYPE gui SYSTEM 'kpartgui.dtd'>
                  <gui name="dolphin" version="49">
                   <MenuBar>
                    <Menu name="file">
                     <Action name="new_menu"/>
                     <Action name="file_new"/>
                     <Action name="new_tab"/>
                     <Action name="file_close"/>
                     <Action name="undo_close_tab"/>
                     <Separator/>
                     <Action name="add_to_places"/>
                     <Separator/>
                     <Action name="renamefile"/>
                     <Action name="duplicate"/>
                     <Action name="movetotrash"/>
                     <Action name="deletefile"/>
                     <Separator/>
                     <Action name="show_target"/>
                     <Separator/>
                     <Action name="properties"/>
                    </Menu>
                    <Menu name="edit">
                     <Action name="edit_cut"/>
                     <Action name="edit_copy"/>
                     <Action name="copy_location"/>
                     <Action name="edit_paste"/>
                     <Separator/>
                     <Action name="show_filter_bar"/>
                     <Action name="edit_find"/>
                     <Separator/>
                     <Action name="toggle_selection_mode"/>
                     <Action name="copy_to_inactive_split_view"/>
                     <Action name="move_to_inactive_split_view"/>
                     <Action name="edit_select_all"/>
                     <Action name="invert_selection"/>
                    </Menu>
                    <Menu name="view">
                     <Action name="view_zoom_in"/>
                     <Action name="view_zoom_reset"/>
                     <Action name="view_zoom_out"/>
                     <Separator/>
                     <Action name="sort"/>
                     <Action name="group_by"/>
                     <Action name="view_mode"/>
                     <Action name="additional_info"/>
                     <Action name="show_preview"/>
                     <Action name="show_hidden_files"/>
                     <Action name="act_as_admin"/>
                     <Separator/>
                     <Action name="restore_view_settings_default"/>
                     <Action name="view_properties"/>
                     <Separator/>
                     <Action name="split_view_menu"/>
                     <Action name="popout_split_view"/>
                     <Action name="focus_inactive_split_view"/>
                     <Action name="split_stash"/>
                     <Action name="redisplay"/>
                     <Action name="stop"/>
                     <Separator/>
                     <Action name="panels"/>
                     <Menu icon="edit-select-text" name="location_bar">
                      <text context="@title:menu">Location Bar</text>
                      <Action name="editable_location"/>
                      <Action name="replace_location"/>
                     </Menu>
                    </Menu>
                    <Menu name="go">
                     <Action name="bookmarks"/>
                     <Action name="closed_tabs"/>
                    </Menu>
                    <Menu name="tools">
                     <Action name="open_preferred_search_tool"/>
                     <Action name="open_terminal"/>
                     <Action name="open_terminal_here"/>
                     <Action name="manage_disk_space"/>
                     <Action name="compare_files"/>
                     <Action name="change_remote_encoding"/>
                    </Menu>
                    <Menu name="settings">
                     <Action name="window_color_sheme"/>
                    </Menu>
                   </MenuBar>
                   <ToolBar alreadyVisited="1" name="mainToolBar" noMerge="1">
                    <Action name="view_settings"/>
                    <text context="@title:menu" translationDomain="dolphin">Main Toolbar</text>
                    <Action name="go_back"/>
                    <Action name="go_forward"/>
                    <Action name="go_up"/>
                    <Action name="view_redisplay"/>
                    <Action name="url_navigators"/>
                    <Action name="split_view"/>
                    <Action name="toggle_search"/>
                    <Action name="hamburger_menu"/>
                   </ToolBar>
                   <State name="new_file">
                    <disable>
                     <Action name="edit_undo"/>
                     <Action name="edit_redo"/>
                     <Action name="edit_cut"/>
                     <Action name="renamefile"/>
                     <Action name="movetotrash"/>
                     <Action name="deletefile"/>
                     <Action name="invert_selection"/>
                     <Separator/>
                     <Action name="go_back"/>
                     <Action name="go_forward"/>
                    </disable>
                   </State>
                   <State name="has_selection">
                    <enable>
                     <Action name="invert_selection"/>
                    </enable>
                   </State>
                   <State name="has_no_selection">
                    <disable>
                     <Action name="delete_shortcut"/>
                     <Action name="invert_selection"/>
                    </disable>
                   </State>
                   <ActionProperties scheme="Default">
                    <Action name="compact" priority="0"/>
                    <Action name="details" priority="0"/>
                    <Action name="edit_copy" priority="0"/>
                    <Action name="edit_cut" priority="0"/>
                    <Action name="edit_paste" priority="0"/>
                    <Action name="go_back" priority="0"/>
                    <Action name="go_forward" priority="0"/>
                    <Action name="go_home" priority="0"/>
                    <Action name="go_up" priority="0"/>
                    <Action name="icons" priority="0"/>
                    <Action name="stop" priority="0"/>
                    <Action name="toggle_filter" priority="0"/>
                    <Action name="toggle_search" priority="0"/>
                    <Action name="view_mode" priority="0"/>
                    <Action name="view_redisplay" priority="0" shortcut="F5; Ctrl+R"/>
                    <Action name="view_settings" priority="0"/>
                    <Action name="view_zoom_in" priority="0"/>
                    <Action name="view_zoom_out" priority="0"/>
                    <Action name="view_zoom_reset" priority="0"/>
                   </ActionProperties>
                  </gui>
                '';

              # No home-manager module for luacheck; verbatim Lua, not data.
              xdg.configFile."luacheck/.luacheckrc".text = # lua
                ''
                  globals = { "vim" }
                '';

              # User-level makepkg.conf override (XDG_CONFIG_HOME/pacman/makepkg.conf).
              # Arch/pacman-specific; no home-manager module and its
              # shell-array syntax doesn't fit a pkgs.formats.* generator.
              xdg.configFile."pacman/makepkg.conf".text = # bash
                ''
                  MAKEFLAGS="--jobs=$(nproc)"
                  BUILDDIR=/tmp/makepkg
                  OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
                  PACMAN_AUTH=sudo
                '';

              # Consumed by .scripts/bin/sandbox, which bind-mounts these by
              # literal path into /etc/claude-code/ inside the sandbox
              # namespace - unrelated to programs.claude-code's own settings
              # (~/.claude/), so path must stay exactly as-is.
              xdg.configFile."claude-code-managed/managed-mcp.json".source =
                (homepkgs.formats.json { }).generate "claude-code-managed-mcp.json"
                  {
                    mcpServers.mcp-nixos = {
                      type = "stdio";
                      command = "mcp-nixos";
                      args = [ ];
                    };
                  };

              xdg.configFile."claude-code-managed/managed-settings.json".source =
                (homepkgs.formats.json { }).generate "claude-code-managed-settings.json"
                  {
                    attribution.sessionUrl = false;
                    env.DISABLE_AUTOUPDATER = 1;
                    permissions.allow = [
                      "mcp__mcp-nixos__nix"
                      "mcp__mcp-nixos__nix_versions"
                    ];
                  };

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

              home.file."revive.toml".source = (homepkgs.formats.toml { }).generate "revive.toml" {
                ignoreGeneratedHeader = false;
                severity = "warning";
                confidence = 0.8;
                errorCode = 0;
                warningCode = 0;

                rule = {
                  context-keys-type = { };
                  time-naming = { };
                  var-declaration = { };
                  unexported-return = { };
                  errorf = { };
                  blank-imports = { };
                  context-as-argument = { };
                  error-return = { };
                  error-strings = { };
                  error-naming = { };
                  exported = { };
                  if-return = { };
                  increment-decrement = { };
                  var-naming = { };
                  package-comments = { };
                  range = { };
                  receiver-naming = { };
                  indent-error-flow = { };
                  cyclomatic.arguments = [ 30 ];
                  empty-block = { };
                  superfluous-else = { };
                  confusing-naming = { };
                  get-return = { };
                  confusing-results = { };
                  deep-exit = { };
                  unused-parameter = { };
                  unreachable-code = { };
                  flag-parameter = { };
                  unnecessary-stmt = { };
                  struct-tag = { };
                  modifies-value-receiver = { };
                  constant-logical-expr = { };
                  bool-literal-in-expr = { };
                  redefines-builtin-id = { };
                  range-val-in-closure = { };
                  range-val-address = { };
                  waitgroup-by-value = { };
                  atomic = { };
                  call-to-gc = { };
                  duplicated-imports = { };
                  import-shadowing = { };
                  unused-receiver = { };
                  unhandled-error = { };
                  cognitive-complexity.arguments = [ 30 ];
                  string-of-int = { };
                  early-return = { };
                  unconditional-recursion = { };
                  identical-branches = { };
                  defer = { };
                  unexported-naming = { };
                };
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
          )
        ];
      };
    };
}
