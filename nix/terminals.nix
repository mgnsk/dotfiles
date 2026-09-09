{ ... }:
{
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
}
