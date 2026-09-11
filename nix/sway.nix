{ pkgs, username, ... }:
{
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
    extraPortals = with pkgs; [
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
    "${pkgs.xdg-desktop-portal-gtk}/share/systemd/user/xdg-desktop-portal-gtk.service";
  xdg.dataFile."systemd/user/xdg-desktop-portal-wlr.service".source =
    "${pkgs.xdg-desktop-portal-wlr}/share/systemd/user/xdg-desktop-portal-wlr.service";

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

      workspaceBindings = pkgs.lib.listToAttrs (
        pkgs.lib.flatten (
          pkgs.lib.genList (
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
              criteria.app_id = "REAPER";
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

        keybindings = pkgs.lib.mkForce (
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
      swaymsg = "${pkgs.sway}/bin/swaymsg";
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
        ExecStart = "${pkgs.writeShellScript "wait-for-tray" ''
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

    # swayidle's vendor unit (home-manager's services.swayidle
    # module) is PartOf=sway-session.target with Restart=always and
    # no StartLimitBurst override, so it has the same restart-storm
    # exposure as xdg-desktop-portal-wlr above: a sway socket churn
    # (crash, session restart) pulls it down and restarts it before
    # systemd --user's environment has caught up, burning through
    # the default 5-in-10s budget in under a second and leaving it
    # permanently failed until something starts it again - which is
    # why `home-manager switch` sometimes reports swayidle.service
    # failed on the first run (it's inheriting a stale failure from
    # before this activation) and clean on the second (that run's
    # own "Starting units" step already cleared it).
    swayidle.Unit = {
      DefaultDependencies = false;
      StartLimitIntervalSec = 30;
      StartLimitBurst = 5;
    };
    swayidle.Service.RestartSec = 2;

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
        ExecStart = "${pkgs.writeShellScript "audio-idle-inhibit" ''
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
}
