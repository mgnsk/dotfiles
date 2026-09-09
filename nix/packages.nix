{
  lib,
  pkgs,
  hostname,
  audioHosts,
  audioPkgs,
  ...
}:
let
  gh-tpl = pkgs.stdenv.mkDerivation rec {
    name = "gh-tpl";
    version = "0.0.9";
    src = pkgs.fetchurl {
      url = "https://github.com/mgnsk/gh-tpl/releases/download/v${version}/gh-tpl-v${version}-linux-amd64.tar.gz";
      sha256 = "1970b39372d421e831098529d71c126014f3d33225fffcdfc03a993aa90a05f4";
    };
    sourceRoot = ".";
    installPhase = ''
      install -m755 -D gh-tpl $out/bin/gh-tpl
    '';
  };

  tusk-go = pkgs.stdenv.mkDerivation rec {
    name = "tusk-go";
    version = "0.8.1";
    src = pkgs.fetchurl {
      url = "https://github.com/rliebz/tusk/releases/download/v${version}/tusk_${version}_linux_amd64.tar.gz";
      sha256 = "3be7a872673c674dbcffbf4cfac2580152edf6d1f072d9be491fb69d2a460761";
    };
    sourceRoot = ".";
    installPhase = ''
      install -m755 -D tusk $out/bin/tusk
    '';
  };

  diff-highlight = pkgs.linkFarm "diff-highlight" [
    {
      name = "bin/diff-highlight";
      path = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
    }
  ];

  pint = pkgs.stdenv.mkDerivation rec {
    name = "pint";
    version = "1.29.0";
    src = pkgs.fetchurl {
      url = "https://github.com/laravel/pint/releases/download/v${version}/pint.phar";
      sha256 = "e29e7a16384c5baacf644d53402e963b320c9ec5c8b4afd20c30cccf9add1c7b";
    };
    phases = [ "installPhase" ]; # Removes all phases except installPhase (no unpackPhase).
    installPhase = ''
      install -m755 -D $src $out/bin/pint
    '';
  };

  homePkgs =
    with pkgs;
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
    # Plugins, wine and yabridge come from the audio flake (nix/audio,
    # its own flake with its own nixpkgs pin and lock file) rather than
    # nixpkgs-home, so REAPER works standalone, with no separate dev
    # shell needed. Gated to audioHosts like inputs.audio.homeModules.audio
    # (see flake.nix), so non-audio hosts don't build/download any of it.
    ++ lib.optionals (builtins.elem hostname audioHosts) audioPkgs;
in
{
  home.packages = homePkgs;
}
