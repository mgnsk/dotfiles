{
  lib,
  pkgs,
  username,
  ...
}:
let
  # Computed once at build time instead of shelling out to vivid on every shell startup.
  lsColors = lib.removeSuffix "\n" (
    builtins.readFile "${pkgs.runCommand "ls-colors-ayu" { }
      "${pkgs.vivid}/bin/vivid generate ayu > $out"
    }"
  );
in
{
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
        # Bash computes $HOSTNAME itself at startup but never exports
        # it; export it so child processes (e.g. nix eval in
        # flake.nix, for the audioHosts check) can see it too.
        export HOSTNAME

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
}
