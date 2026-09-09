{
  pkgs,
  inputs,
  username,
  ...
}:
let
  mozillaAddons = import inputs.firefox-addons { inherit pkgs; };
  firefoxAddons = mozillaAddons.firefox-addons;

  # Not packaged in nur-expressions' thunderbird-addons set, so built
  # directly from the upstream .xpi the same way that set's entries are.
  dkimVerifierExtension =
    mozillaAddons.lib.mozilla.mkBuildMozillaXpiAddon
      {
        inherit (pkgs) fetchurl stdenv;
      }
      {
        pname = "dkim-verifier";
        version = "6.3.0";
        addonId = "dkim_verifier@pl";
        url = "https://github.com/lieser/dkim_verifier/releases/download/v6.3.0/dkim_verifier-6.3.0.xpi";
        sha256 = "5ae95b4d560257b2e5722e1d3824a4031fb74d5d57b790dfc12f76a11dc1501a";
        meta = with pkgs.lib; {
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
  bravePolicyFile = pkgs.writeText "brave-policy.json" (
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
in
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
    configPath = ".mozilla/firefox";

    # web-eid needs its native messaging host manifest linked in
    # for the extension to talk to the smart card app.
    nativeMessagingHosts = [ pkgs.web-eid-app ];

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
    package = pkgs.brave-origin;

    # web-eid needs its native messaging host manifest linked in
    # for the extension to talk to the smart card app.
    nativeMessagingHosts = [ pkgs.web-eid-app ];

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
    package = pkgs.thunderbird;

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
}
